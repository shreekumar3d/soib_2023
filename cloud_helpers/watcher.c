/*
 * watcher - watches a directory and its descendant tree
 * Dumps files that are (newly) created, but not directories
 *
 * May be useful for monitoring cloud run
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/inotify.h>
#include <sys/stat.h>
#include <unistd.h>
#include <limits.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/inotify.h>
#include <sys/stat.h>
#include <unistd.h>
#include <limits.h>
#include <errno.h>
#include <time.h>

#define EVENT_SIZE  (sizeof(struct inotify_event))
#define EVENT_BUF_LEN   (1024 * (EVENT_SIZE + NAME_MAX + 1))

typedef struct Watch {
    int wd;
    char path[PATH_MAX];
    struct Watch *next;
} Watch;

Watch *watch_list = NULL;

// Add a directory to inotify and watchlist
int add_watch(int fd, const char *path) {
    int wd = inotify_add_watch(fd, path, IN_CREATE | IN_ONLYDIR | IN_ISDIR);
    if (wd == -1) {
        perror("inotify_add_watch");
        return -1;
    }
    Watch *w = malloc(sizeof(Watch));
    w->wd = wd;
    strncpy(w->path, path, PATH_MAX);
    w->next = watch_list;
    watch_list = w;
    return wd;
}

// Find the path for a given watch descriptor
char *wd_to_path(int wd) {
    Watch *w = watch_list;
    while (w) {
        if (w->wd == wd) return w->path;
        w = w->next;
    }
    return NULL;
}

// Recursively add watches to all directories
void add_watches_recursive(int fd, const char *root) {
    add_watch(fd, root);

    DIR *dir = opendir(root);
    if (!dir) return;
    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
            continue;
        char path[PATH_MAX];
        snprintf(path, PATH_MAX, "%s/%s", root, entry->d_name);
        struct stat st;
        if (stat(path, &st) == 0 && S_ISDIR(st.st_mode)) {
            add_watches_recursive(fd, path);
        }
    }
    closedir(dir);
}

// Helper to print creation time in YYYY-MM-DD HH:MM:SS
void print_creation_time(const char *path) {
    struct stat st;
    if (stat(path, &st) == 0) {
#if defined(__linux__) && defined(st_birthtime)
        time_t t = st.st_birthtime;
#else
        // Linux may not support st_birthtime, use st_ctime (inode change time) or current time
        time_t t = st.st_ctime;
#endif
        struct tm *tm_info = localtime(&t);
        char buffer[PATH_MAX];
        strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", tm_info);
        printf("%s %s\n", buffer,path);
    } else {
        perror("stat");
    }
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <directory>\n", argv[0]);
        return 1;
    }

    int fd = inotify_init();
    if(fd < 0) {
        perror("inotify_init");
        return 2;
    }

    add_watches_recursive(fd, argv[1]);

    char buffer[EVENT_BUF_LEN];
    while (1) {
        int length = read(fd, buffer, EVENT_BUF_LEN);
        if (length < 0) {
            perror("read");
            break;
        }

        int i = 0;
        while (i < length) {
            struct inotify_event *event = (struct inotify_event*) &buffer[i];
            // Full path construction
            char *parent = wd_to_path(event->wd);

            if (event->mask & IN_CREATE) {
                char path[PATH_MAX];
                snprintf(path, PATH_MAX, "%s/%s", parent, event->name);

                struct stat st;
                if (stat(path, &st) == 0) {
                    if (S_ISDIR(st.st_mode)) {
                        // For newly created directories, watch them too
                        add_watches_recursive(fd, path);
                    } else if (S_ISREG(st.st_mode)) {
                        print_creation_time(path);
                    }
                }
            }
            i += EVENT_SIZE + event->len;
        }
    }

    close(fd);
    return 0;
}

