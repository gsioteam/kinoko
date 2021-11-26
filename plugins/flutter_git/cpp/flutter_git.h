
#ifndef FLUTTER_GIT_H
#define FLUTTER_GIT_H

typedef struct _GitRepository GitRepository;

typedef struct _GitController GitController;

void flutter_init();
void flutter_set_cacert_path(const char *path);
int flutter_open_repository(GitRepository *repo);
void flutter_delete_repository(GitRepository *repo);
void flutter_clone(GitController *controller);
void flutter_fetch(GitController *controller);
void flutter_checkout(GitController *controller);
char* flutter_get_sha1(GitRepository *repo, const char *path);

#endif //FLUTTER_GIT_H
