//
// Created by gen on 11/19/21.
//

#include <malloc.h>
#include <string.h>
#include <git2.h>
#include <stdbool.h>
#include <pthread.h>
#include "bmt.h"

typedef struct {
    const char *path;
    git_repository *repo;
} GitRepository;

typedef struct {
    int id;
    int canceled;
    char *arg_1;
    char *arg_2;
    GitRepository *repo;
} GitController;

bool flutter_inited = false;

void flutter_init() {
    if (!flutter_inited) {
        git_libgit2_init();
        flutter_inited = true;
    }
}

int perform_fastforward(const char* branch, git_repository *repo, git_oid *target_oid, int is_unborn)
{
    git_checkout_options ff_checkout_options = GIT_CHECKOUT_OPTIONS_INIT;
    git_reference *target_ref;
    git_reference *new_target_ref;
    git_reference  *local_ref = NULL;
    git_object *target = NULL;
    int err = 0;
    char local_name[128];

    sprintf(local_name, "refs/heads/%s", branch);

    err = git_reference_lookup(&local_ref, repo, local_name);
    if (err == GIT_ENOTFOUND) {
    } else if (err != 0 || git_reference_type(local_ref) != GIT_REFERENCE_DIRECT) {
        fprintf(stderr, "failed to lookup HEAD ref\n");
        return -1;
    }

    if (is_unborn) {
        const char *symbolic_ref;
//            git_reference *ref;

        char fullname[128];
        sprintf(fullname, "refs/remotes/origin/%s", branch);
        err = git_reference_lookup(&target_ref, repo, fullname);
        if (err != 0 || git_reference_type(target_ref) != GIT_REFERENCE_DIRECT) {
            fprintf(stderr, "failed to lookup HEAD ref\n");
            return -1;
        }

        git_oid_cpy(target_oid, git_reference_target(target_ref));
//            /* Grab the reference HEAD should be pointing to */
//            symbolic_ref = git_reference_symbolic_target(ref);
//
//            /* Create our master reference on the target OID */
//            err = git_reference_create(&target_ref, repo, symbolic_ref, target_oid, 0, NULL);
//            if (err != 0) {
//                fprintf(stderr, "failed to create master reference\n");
//                return -1;
//            }

//            git_reference_free(ref);
        if (local_ref == NULL) {
            err = git_reference_create(&local_ref, repo, local_name, target_oid, true, NULL);
            if (err != 0) {
                fprintf(stderr, "failed to create master reference\n");
                return -1;
            }
        }

    } else {
        /* HEAD exists, just lookup and resolve */
        err = git_repository_head(&target_ref, repo);
        if (err != 0) {
            fprintf(stderr, "failed to get HEAD reference\n");
            return -1;
        }
    }

    /* Lookup the target object */
    err = git_object_lookup(&target, repo, target_oid, GIT_OBJECT_COMMIT);
    if (err != 0) {
        fprintf(stderr, "failed to lookup OID %s\n", git_oid_tostr_s(target_oid));
        return -1;
    }

    /* Checkout the result so the workdir is in the expected state */
    ff_checkout_options.checkout_strategy = GIT_CHECKOUT_FORCE;
    err = git_checkout_tree(repo, target, &ff_checkout_options);
    if (err != 0) {
        fprintf(stderr, "failed to checkout HEAD reference\n");
        return -1;
    }

    /* Move the target reference to the target OID */
    err = git_reference_set_target(&new_target_ref, local_ref, target_oid, NULL);
    if (err != 0) {
        fprintf(stderr, "failed to move HEAD reference\n");
        return -1;
    }

    git_reference_free(local_ref);
    git_reference_free(target_ref);
    git_reference_free(new_target_ref);
    git_object_free(target);

    return 0;
}

void flutter_set_cacert_path(const char *path) {
    git_libgit2_opts(GIT_OPT_SET_SSL_CERT_LOCATIONS, path, NULL);
}

int flutter_open_repository(GitRepository *repo) {
    return git_repository_open(&repo->repo, repo->path);
}

void flutter_delete_repository(GitRepository *repo) {
    if (repo->repo)
        git_repository_free(repo->repo);
}

int fetch_progress(const git_indexer_progress *stats, void *payload) {
    GitController *controller = (GitController *)payload;
    if (controller->canceled) {
        return -3;
    }

    uint32_t received = stats->received_objects, total = stats->total_objects;
    char name[64];
    sprintf(name, "event:%d", controller->id);
    char data[64];
    sprintf(data, "fetch:%u/%u", received, total);
    bmt_sendEvent(name, data);
    return 0;
}

void checkout_progress(
        const char *path,
        size_t completed_steps,
        size_t total_steps,
        void *payload) {
    GitController *controller = (GitController *)payload;

    char name[64];
    sprintf(name, "event:%d", controller->id);
    char data[64];
    sprintf(data, "checkout:%u/%u", completed_steps, total_steps);
    bmt_sendEvent(name, data);
}

void sendError(GitController *controller) {
    char name[64];
    sprintf(name, "event:%d", controller->id);
    char data[256];
    sprintf(data, "error:%s", git_error_last()->message);
    bmt_sendEvent(name, data);
}

void* clone_thread(void *arg) {
    GitController *controller = (GitController *)arg;

    git_clone_options ops = GIT_CLONE_OPTIONS_INIT;

    ops.fetch_opts.callbacks.transfer_progress = fetch_progress;
    ops.fetch_opts.callbacks.payload = controller;

    ops.checkout_opts.progress_cb = checkout_progress;
    ops.checkout_opts.progress_payload = controller;

    if (git_clone(&controller->repo->repo, controller->arg_1, controller->repo->path, &ops) != 0) {
        sendError(controller);
    } else {
        git_oid ret;
        if (perform_fastforward(controller->arg_2, controller->repo->repo, &ret, 1) != 0) {
            sendError(controller);
            return NULL;
        }

        char name[64];
        sprintf(name, "event:%d", controller->id);
        bmt_sendEvent(name, "complete:success");
    }
    return NULL;
}

void flutter_clone(GitController *controller) {

    pthread_t pthread;
    pthread_create(&pthread, NULL, clone_thread, controller);
    pthread_detach(pthread);

}

void* fetch_thread(void *arg) {
    GitController *controller = (GitController *) arg;

    git_remote *remote = NULL;
    git_remote_lookup(&remote, controller->repo->repo, controller->arg_1);

    if (!remote) {
        char name[64];
        sprintf(name, "event:%d", controller->id);
        bmt_sendEvent(name, "error:no_remote");
    } else {
        git_fetch_options ops = GIT_FETCH_OPTIONS_INIT;

        ops.callbacks.transfer_progress = fetch_progress;
        ops.callbacks.payload = controller;

        if (git_remote_fetch(remote, NULL, &ops, NULL) != 0) {
            sendError(controller);
        } else {
            char name[64];
            sprintf(name, "event:%d", controller->id);
            bmt_sendEvent(name, "complete:success");
        }
    }

    return NULL;
}

void flutter_fetch(GitController *controller) {
    pthread_t pthread;
    pthread_create(&pthread, NULL, fetch_thread, controller);
    pthread_detach(pthread);
}

int repository_fetchhead_foreach_cb2(const char *ref_name,
                                     const char *remote_url,
                                     const git_oid *oid,
                                     unsigned int is_merge,
                                     void *payload) {
    git_oid *result = (git_oid *)payload;
    *result = *oid;
    return -1;
}

void *checkout_thread(void *arg) {
    GitController *controller = (GitController *) arg;
    git_oid ret;
    git_repository_fetchhead_foreach(controller->repo->repo, repository_fetchhead_foreach_cb2, &ret);
    if (perform_fastforward(controller->arg_1, controller->repo->repo, &ret, 1) != 0) {
        sendError(controller);
    } else {
        char name[64];
        sprintf(name, "event:%d", controller->id);
        bmt_sendEvent(name, "complete:success");
    }

    return NULL;
}

void flutter_checkout(GitController *controller) {
    pthread_t pthread;
    pthread_create(&pthread, NULL, checkout_thread, controller);
    pthread_detach(pthread);
}

char* oid_str(const unsigned char *oid) {
    char *res = malloc((GIT_OID_RAWSZ * 2 + 1)*sizeof(char));
    for (int i = 0; i < GIT_OID_RAWSZ; ++i) {
        sprintf(res+i*2, "%02x", oid[i]);
    }
    res[GIT_OID_RAWSZ * 2] = 0;
    return res;
}

char* flutter_get_sha1(GitRepository *repo, const char *path) {
    git_object *obj = NULL;
    git_revparse_single(&obj, repo->repo, path);
    if (obj) {
        const unsigned char *chs = git_object_id(obj)->id;
        char *ret = oid_str(chs);
        git_object_free(obj);
        return ret;
    }
    return NULL;
}