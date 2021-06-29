//
// Created by gen on 2020/5/29.
//

#include "GitRepository.h"
#include <thread>
#include <git2.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include "Platform.h"
#include "../gs_define.h"

using namespace gs;
using namespace gc;
using namespace std;

namespace gs {
    CLASS_BEGIN_NV(GitTask, gc::Object)
        std::thread thd;
        bool is_cancel;
        Wk<GitAction> action;
        std::function<const char*(GitTask *)> func;

        static int fetch_progress(const git_indexer_progress *stats, void *payload) {
            GitTask *that = (GitTask *)payload;
            if (that->is_cancel) {
                return -3;
            }
            Ref<GitAction> action = that->action.lock();
            if (action) {
                if (action->on_progress) {
                    uint32_t received = stats->received_objects, total = stats->total_objects;
                    Platform::doOnMainThread(C([=](){
                        action->on_progress("fetch", received, total);
                    }));
                }
            }
            return 0;
        }

        static void checkout_progress(
                const char *path,
                size_t completed_steps,
                size_t total_steps,
                void *payload) {
            GitTask *that = (GitTask *)payload;
            Ref<GitAction> action = that->action.lock();
            if (action) {
                if (action->on_progress) {
                    Platform::doOnMainThread(C([=](){
                        action->on_progress("checkout", completed_steps, total_steps);
                    }));
                }
            }
        }

    public:

        GitTask(std::function<const char*(GitTask *)> func, const Wk<GitAction> &action) : action(action) {
            this->func = func;
            thd = thread(bind(&GitTask::main, this));
            thd.detach();
        }

        void cancel() {
            is_cancel = true;
        }

        void processFetchCb(git_fetch_options &ops) {
            ops.callbacks.transfer_progress = fetch_progress;
            ops.callbacks.payload = this;
//            ops.callbacks.certificate_check;
        }

        void processCheckoutCb(git_checkout_options &ops) {
            ops.progress_cb = checkout_progress;
            ops.progress_payload = this;
        }

        void main() {
            gc::Ref<GitTask> ref(this);
            const char *err = func(this);
            Ref<GitAction> action = this->action.lock();
            if (action) {
                if (err) {
                    action->error = err;
                } else {
                }
                Platform::doOnMainThread(C([=](){
                    if (action->on_complete)
                        action->on_complete();
                }));
            }
        }
    CLASS_END

    std::string oid_str(const unsigned char *oid) {
        char res[9];
        for (int i = 0; i < 4; ++i) {
            sprintf(res+i*2, "%02x", oid[i]);
        }
        res[7] = 0;
        return res;
    }

    int repository_fetchhead_foreach_cb(const char *ref_name,
            const char *remote_url,
            const git_oid *oid,
            unsigned int is_merge,
            void *payload) {
        string *result = (string *)payload;
        *result = oid_str(oid->id);
        return -1;
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


    static int perform_fastforward(string branch, git_repository *repo, git_oid *target_oid, int is_unborn)
    {
        git_checkout_options ff_checkout_options = GIT_CHECKOUT_OPTIONS_INIT;
        git_reference *target_ref;
        git_reference *new_target_ref;
        git_reference  *local_ref;
        git_object *target = NULL;
        int err = 0;
        if (branch.empty())
            branch = "master";
        {
            string name = "refs/heads/" + branch;

            err = git_reference_lookup(&local_ref, repo, name.c_str());
            if (err != 0 || git_reference_type(local_ref) != GIT_REFERENCE_DIRECT) {
                fprintf(stderr, "failed to lookup HEAD ref\n");
                return -1;
            }
        }

        if (is_unborn) {
            const char *symbolic_ref;
//            git_reference *ref;

            string fullname = "refs/remotes/origin/" + branch;
            err = git_reference_lookup(&target_ref, repo, fullname.c_str());
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
        ff_checkout_options.checkout_strategy = GIT_CHECKOUT_SAFE;
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
}

bool GitRepository::is_setup = false;
std::string GitRepository::root_path;

GitAction::GitAction(std::function<const char *(GitTask *)> main) {
    task = new GitTask(main, this);
}
GitAction::~GitAction() {
    task->cancel();
}

void GitAction::cancel() {
    task->cancel();
}

GitRepository::GitRepository() {}

GitRepository::~GitRepository() {
    if (repo) {
        git_repository_free(repo);
    }
    if (remote) {
        git_remote_free(remote);
    }
}

void GitRepository::initialize(const std::string &path, const string &branch) {
    std::string str = root_path;
    if (path[0] == '/') {
        str += path;
    } else {
        str += '/' + path;
    }
    this->path = str;
    this->branch = branch;

    if (git_repository_open(&repo, this->path.c_str()) < 0) {
        repo = nullptr;
    }
}

void GitRepository::setup(const std::string &path) {
    if (!is_setup) {
        is_setup = true;
        git_libgit2_init();
        root_path = path + "/repo";
    }
}

void GitRepository::setCacertPath(const std::string &path) {
    git_libgit2_opts(GIT_OPT_SET_SSL_CERT_LOCATIONS, path.c_str(), NULL);
}

void GitRepository::shutdown() {
    if (is_setup) {
        is_setup = false;
        git_libgit2_shutdown();
    }
}

void GitRepository::removeFile(const char *path) {
    struct stat st;
    if (stat(path, &st) == 0) {
        if (S_ISDIR(st.st_mode)) {
            DIR *dir = opendir(path);
            struct dirent *ent = nullptr;
            while ((ent = readdir(dir))) {
                if (strcmp(ent->d_name, "..") == 0 || strcmp(ent->d_name, ".") == 0) continue;
                char subpath[2048];
                sprintf(subpath, "%s/%s", path, ent->d_name);
                removeFile(subpath);
            }
            closedir(dir);
            if (rmdir(path) != 0) {
                LOG(e, "Delete dir failed %s(%s)", path, strerror(errno));
            }
        } else {
            if (unlink(path) != 0) {
                LOG(e, "Delete file failed %s(%s)", path, strerror(errno));
            }
        }
    }
}

#define CheckError(CODE) if ((CODE) != 0) {return git_error_last()->message;}

Ref<GitAction> GitRepository::cloneFromRemote(const std::string &url) {
    Ref<GitRepository> repo(this);
    return new GitAction([=](GitTask *task) {
        if (access(path.c_str(), R_OK) == 0) {
            removeFile(path.c_str());
        }
        git_clone_options ops = GIT_CLONE_OPTIONS_INIT;
        task->processFetchCb(ops.fetch_opts);
        task->processCheckoutCb(ops.checkout_opts);
        if (git_clone(&repo->repo, url.c_str(), path.c_str(), &ops) != 0) {
            return git_error_last()->message;
        }
        git_oid ret;
        CheckError(perform_fastforward(repo->branch, repo->repo, &ret, 1));

        return (char *)nullptr;
    });
}

gc::Ref<GitAction> GitRepository::fetch() {
    if (!remote) {
        git_remote_lookup(&remote, repo, "origin");
    }
    Ref<GitRepository> repo(this);
    return new GitAction([=](GitTask *task){
        if (!repo->remote) {
            return "No remote";
        }

        git_fetch_options ops = GIT_FETCH_OPTIONS_INIT;
        task->processFetchCb(ops);
        if (git_remote_fetch(repo->remote, nullptr, &ops, nullptr) != 0) {
            return (const char *)git_error_last()->message;
        }
        LOG(i, "Fetch complete");
        return (const char *)nullptr;
    });
}

std::string GitRepository::localID() const {
    if (repo) {
        git_object *obj = nullptr;
        string fullname = "refs/heads/" + (branch.empty() ? string("master") : branch);
        git_revparse_single(&obj, repo, fullname.c_str());
        if (obj) {
            const unsigned char *chs = git_object_id(obj)->id;
            std::string ret = oid_str(chs);
            git_object_free(obj);
            return ret;
        }
    }
    return "";
}

std::string GitRepository::highID() {
    string ret = localID();
    if (repo) {
        git_repository_fetchhead_foreach(repo, repository_fetchhead_foreach_cb, &ret);
    }
    return ret;
}

Ref<GitAction> GitRepository::checkout() {
    Ref<GitRepository> repo(this);
    return new GitAction([=](GitTask *task){
        git_oid ret;
        git_repository_fetchhead_foreach(repo->repo, repository_fetchhead_foreach_cb2, &ret);
        CheckError(perform_fastforward(repo->branch, repo->repo, &ret, 1));

        return (char *)nullptr;
    });
}