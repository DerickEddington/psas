// TODO: Review what calls should retry on EINTR

// TODO: Generalize to not assume 64-bit CPU (e.g. for pointer size).


#define _GNU_SOURCE

#include <stdlib.h>
#include <unistd.h>
#include <limits.h>
#include <fnmatch.h>
#include <fcntl.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <error.h>
#include <stdio.h>
#ifdef DEBUG
  #include <signal.h>
#endif

#include "system_interface.h"


#define YES 1
#define NO 0


#ifdef DEBUG
#define dprintf(...) fprintf(stderr, __VA_ARGS__);
#else
#define dprintf(...) ;
#endif


#ifdef DEBUG
static void sigsegv_print (int signum, siginfo_t* si, void* ctxt)
{
  void w (char* m, size_t s) { write(STDERR_FILENO, m, s); }
  void hw (uintptr_t x) {
    static char hex[] = {'0','1','2','3','4','5','6','7',
                         '8','9','A','B','C','D','E','F'};
    for (int c = (sizeof(uintptr_t) * 2) - 1; c >= 0; c--) {
      unsigned int i = (x & (((uintptr_t)0xF) << 4*c)) >> 4*c;
      w(&hex[i], 1);
    }
  }
  static char m1[] = "\nSIGSEGV: ";
  static char m2[] = "SEGV_MAPERR: ";
  static char m3[] = "SEGV_ACCERR: ";
  static char m4[] = "UNKNOWN(";
  static char m5[] = ") ";
  w(m1, sizeof(m1) - 1);
  switch (si->si_code) {
  case SEGV_MAPERR:
    w(m2, sizeof(m2) - 1);
    break;
  case SEGV_ACCERR:
    w(m3, sizeof(m3) - 1);
    break;
  default:
    w(m4, sizeof(m4) - 1);
    hw(si->si_code);
    w(m5, sizeof(m5) - 1);
  }
  hw((uintptr_t) si->si_addr);
  w("\n", 1);
  // Allow this handler to return, so that the faulting instruction will be
  // retried again, now that the handler is uninstalled (because it was
  // installed SA_RESETHAND), which should cause SIGSEGV again but it won't be
  // handled by this handler.
}
#endif


static void die (const char* who, const char* msg, int e) {
  error(EXIT_FAILURE, (e ? errno : 0), "%s: %s", who, msg);
}


static long pagesize;


static int ismapped (const void* addr, size_t length)
{
  const void* end = addr + length;
  unsigned char vec[1];
  int r;
  while (addr < end) {
    r = mincore((void*)addr, pagesize, vec);
    if (r == 0) return YES;
    else if (errno == ENOMEM) addr += pagesize;
    else die("ismapped", "mincore", YES);
  }
  return NO;
}


static int oflags_for_mprot (int prot) {
  return (prot & PROT_WRITE) ? O_RDWR : O_RDONLY;
}


static int segments_dirfd;


#define SEGMENT_FILENAME_STRSIZE (4*5+3+1)


static void segment_addr_to_filename (const void* addr, int mprot,
                                      char filename[SEGMENT_FILENAME_STRSIZE])
{
  void fail (const char* msg) { die("segment_addr_to_filename", msg, YES); }
  char a[16+1];
  if(snprintf(a, sizeof(a), "%016lX", (uintptr_t) addr)
     != sizeof(a) - 1) fail("snprintf a");
  int n;
  for (n = 0; n < 4; n++) {
    if(snprintf(&filename[5*n], 5+1, "%c%c%c%c_",
                a[4*n+0], a[4*n+1], a[4*n+2], a[4*n+3])
       != 5) fail("snprintf %c%c%c%c_");
  }
  if(snprintf(&filename[5*n], 3+1, "%c%c%c",
              (PROT_READ &  mprot ? 'R' : '_'),
              (PROT_WRITE & mprot ? 'W' : '_'),
              (PROT_EXEC &  mprot ? 'X' : '_'))
     != 3) fail("snprintf %c%c%c");
}


static int parse_addr (const char* str, const void** addr)
{
  char addrstr[16+1];
  int sfn = sscanf(str, " %4c_%4c_%4c_%4c ",
                   &addrstr[0], &addrstr[4], &addrstr[8], &addrstr[12]);
  if (sfn != 4) return YES;
  addrstr[sizeof(addrstr) - 1] = '\0';
  //dprintf("addrstr=%s\n", addrstr);
  const void* addr_;
  sfn = sscanf(addrstr, "%p", &addr_);
  if (sfn != 1) return YES;
  //dprintf("addr_=%p\n", addr_);
  *addr = addr_;
  return NO;  // No error.
}


static int segment_filename_to_addr (const char* name,
                                     const void** addr,
                                     int* mprot)
{
  if (parse_addr(name, addr)) return YES;
  //dprintf("*addr=%p\n", *addr);
  char segR, segW, segX;
  int sfn = sscanf(&name[SEGMENT_FILENAME_STRSIZE - (3+1)], "%c%c%c",
                   &segR, &segW, &segX);
  if (sfn != 3) return YES;
  //dprintf("segR=%c, segW=%c, segX=%c\n", segR, segW, segX);
  int mprot_ = 0;
  if (segR != 'R' && segW != 'W' && segX != 'X') mprot_ = PROT_NONE;
  if (segR == 'R') mprot_ |= PROT_READ;
  if (segW == 'W') mprot_ |= PROT_WRITE;
  if (segX == 'X') mprot_ |= PROT_EXEC;
  *mprot = mprot_;
  return NO;  // No error.
}


static const char* alloc_segment_filename = ".alloc_segment_1";


static void* alloc_segment (size_t length, int mprot)
{
  void fail (const char* msg) { die("alloc_segment", msg, YES); }

  dprintf("alloc_segment (%zu, %d) : ", length, mprot);

  // First, open for writing to make it the given size.
  int fd = openat(segments_dirfd, alloc_segment_filename,
                  O_CREAT | O_EXCL | O_WRONLY,
                  S_IRUSR | S_IWUSR);
  if (fd == -1) fail("openat");
  if (ftruncate(fd, length)) fail("ftruncate");
  if(close(fd)) fail("close");

  // Re-open with mode appropriate for the given mmap protection.
  fd = openat(segments_dirfd, alloc_segment_filename, oflags_for_mprot(mprot));
  if (fd == -1) fail("openat");

  void* addr = mmap(NULL, length, mprot, MAP_SHARED, fd, 0);
  if (addr != MAP_FAILED) {
    char addr_filename[SEGMENT_FILENAME_STRSIZE];
    segment_addr_to_filename(addr, mprot, addr_filename);
    if (renameat(segments_dirfd, alloc_segment_filename,
                 segments_dirfd, addr_filename))
      fail("renameat");
  } else {
    if(unlinkat(segments_dirfd, alloc_segment_filename, 0)) fail("unlinkat");
  }
  if(close(fd)) fail("close");

  dprintf("%p\n", addr);
  return addr;  // Might be MAP_FAILED
}


static int free_segment (const void* addr)
{
  void fail (const char* msg) { die("free_segment", msg, YES); }

  dprintf("free_segment (%p) : ", addr);

  struct stat st;

  char fn[SEGMENT_FILENAME_STRSIZE];
  segment_addr_to_filename(addr, 0, fn);

  static const char* const prots[8] = {
    "RW_", "R__", "R_X", "RWX", "__X", "_W_", "_WX", "___"
  };
  int i;
  for (i = 0; i < 8; i++) {
    strncpy(&fn[SEGMENT_FILENAME_STRSIZE - 4], prots[i], 4);
    int fd = openat(segments_dirfd, fn, O_RDONLY);
    if (fd == -1) continue;
    if (fstat(fd, &st)) fail("fstat");
    if (close(fd)) fail("close");
    break;
  }
  if (i == 8) return YES;  // Error: No corresponding segment file.

  if(munmap((void*)addr, st.st_size)) return YES;  // Error: munmap error.
  if(unlinkat(segments_dirfd, fn, 0)) fail("unlinkat");

  dprintf("OK\n");
  return NO;  // No error.
}


static size_t console_read (void* dest, size_t length)
{
  if (length > SSIZE_MAX) die("console_read", "length > SSIZE_MAX", NO);
  ssize_t r = read(STDIN_FILENO, dest, length);
  if (r == -1) die("console_read", "read", YES);
  return r;
}


static size_t console_write (const void* src, size_t length)
{
  ssize_t r = write(STDOUT_FILENO, src, length);
  if (r == -1) die("console_write", "write", YES);
  return r;
}


static void (*entry_point) (const struct system_interface *);


static struct system_interface sys_iface = {
  .alloc_segment = alloc_segment,
  .free_segment  = free_segment,
  .console_read  = console_read,
  .console_write = console_write,
  .exit          = exit
};


int main (int argc, const char** argv)
{
  pagesize = sysconf(_SC_PAGESIZE);

  void initialize (void)
  {
    void fail (const char* msg) { die("initialize", msg, YES); }

    // (If this becomes multi-threaded, alloc_segment_filename will need to be
    // enhanced to be unique per thread or something.)

    // Map all segment files existing in given directory.

    int filter (const struct dirent* x) {
      int r = fnmatch("[0-9A-F][0-9A-F][0-9A-F][0-9A-F]_[0-9A-F][0-9A-F][0-9A-F][0-9A-F]_[0-9A-F][0-9A-F][0-9A-F][0-9A-F]_[0-9A-F][0-9A-F][0-9A-F][0-9A-F]_[R_][W_][X_]",
                      x->d_name,
                      FNM_PATHNAME);
      if (r == FNM_NOMATCH) return NO;
      else if (r != 0) fail("fnmatch");
      return YES;
    }

    struct dirent** namelist;
#if __GLIBC_PREREQ (2,15)
    int sdn = scandirat(segments_dirfd, ".", &namelist, filter, versionsort);
    if (sdn < 0) fail("scandirat");
#else
    int sdn = scandir(argv[1], &namelist, filter, versionsort);
    if (sdn < 0) fail("scandir");
#endif

    for (int i = 0; i < sdn; i++) {
      const char* name = namelist[i]->d_name;
      dprintf("Segment file: %s\n", name);
      const void* addr;
      int mprot;
      if (segment_filename_to_addr(name, &addr, &mprot))
        die("initialize", "matched filename did not parse", NO);
      int fd = openat(segments_dirfd, name, oflags_for_mprot(mprot));
      if (fd == -1) fail("open");
      struct stat st;
      if (fstat(fd, &st)) fail("fstat");

      if (ismapped(addr, st.st_size)) die("initialize", "already mapped", NO);
      void* mm = mmap((void*)addr, st.st_size,
                      mprot, MAP_FIXED | MAP_SHARED,
                      fd, 0);
      if (mm == MAP_FAILED) fail("mmap");
      if (close(fd) == -1) fail("close");

      free(namelist[i]);
    }
    free(namelist);
  }

  void transfer_control (void) {
    dprintf("------ Transferring Control ------\n");
    entry_point(&sys_iface);
  }

  void invalid_args (void) { die("main", "invalid arguments", NO); }

  void fail (const char* msg) { die("main", msg, YES); }

  if (argc != 3
      || strlen(argv[1]) == 0
      || strlen(argv[2]) == 0)
    invalid_args();

  DIR* ds = opendir(argv[1]);
  if (ds == NULL) fail("opendir");
  segments_dirfd = dirfd(ds);
  if (segments_dirfd == -1) fail("dirfd");

  if (parse_addr(argv[2], (const void**) &entry_point)) {
    // If it's not an address, expect it to be a symlink to a file whose name is
    // a segment filename whose address is the entry point.
    struct stat st;
    if (fstatat(segments_dirfd, argv[2], &st, AT_SYMLINK_NOFOLLOW))
      fail("fstatat");
    char target[st.st_size + 1];
    ssize_t r = readlinkat(segments_dirfd, argv[2], target, sizeof(target));
    if (r < 0) fail("readlinkat");
    if (r > st.st_size) die("main", "stat-readlink race", NO);
    target[r] = '\0';
    int mprot;
    if (segment_filename_to_addr(target, (const void**) &entry_point, &mprot))
      invalid_args();
  }

#ifdef DEBUG
  // Install SIGSEGV handler that prints, to help debugging.
  struct sigaction sa;
  sa.sa_flags = SA_SIGINFO | SA_RESETHAND;
  sa.sa_sigaction = sigsegv_print;
  if (sigaction(SIGSEGV, &sa, NULL)) fail("sigaction");
  //*((int*)0x00007123456789A0) = 123;  // Cause SIGSEGV to test.
#endif

  initialize();
  transfer_control();

  fprintf(stderr, "Control returned to C main.\n");
  return 0;
}
