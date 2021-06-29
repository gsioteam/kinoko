//
// Created by gen on 2020/5/29.
//

#ifndef ANDROID_GIT_H
#define ANDROID_GIT_H

#include <core/Ref.h>
#include <core/Callback.h>
#include <core/String.h>
#include "../gs_define.h"

typedef struct git_repository git_repository;
typedef struct git_remote git_remote;
namespace gs {
    class GitTask;

    CLASS_BEGIN_NV(GitAction, gc::Object)
        gc::Ref<GitTask> task;
        gc::Callback on_progress;
        gc::Callback on_complete;
        gc::String error;

        friend class GitTask;

    public:
        GitAction(std::function<const char *(GitTask *)> main);
        ~GitAction();

        METHOD void setOnProgress(const gc::Callback &on_progress) {
            this->on_progress = on_progress;
        }
        METHOD void setOnComplete(const gc::Callback &on_complete) {
            this->on_complete = on_complete;
        }
        METHOD std::string getError() const {
            return error.str();
        }
        METHOD bool hasError() const {
            return error;
        }
        METHOD void cancel();

        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_METHOD(cls, GitAction, setOnProgress);
            ADD_METHOD(cls, GitAction, setOnComplete);
            ADD_METHOD(cls, GitAction, cancel);
            ADD_METHOD(cls, GitAction, getError);
            ADD_METHOD(cls, GitAction, hasError);
        ON_LOADED_END

    CLASS_END

    CLASS_BEGIN_N(GitRepository, gc::Object)

        static bool is_setup;
        static std::string root_path;
        std::string path;
        std::string branch;
        git_repository *repo = nullptr;
        git_remote *remote = nullptr;

        void removeFile(const char *path);

    public:
        GitRepository();
        ~GitRepository();

        METHOD void initialize(const std::string &path, const std::string &branch);

        METHOD static void setup(const std::string &root_path);

        METHOD static void setCacertPath(const std::string &path);

        METHOD static void shutdown();

        METHOD bool isOpen() const {
            return repo != nullptr && !localID().empty();
        }

        METHOD std::string getPath() const {
            return path;
        }

        METHOD std::string localID() const;
        METHOD std::string highID();

//        METHOD std::string remoteID() const;

        METHOD gc::Ref<GitAction> cloneFromRemote(const std::string &url);
        METHOD gc::Ref<GitAction> fetch();
        METHOD gc::Ref<GitAction> checkout();

        ON_LOADED_BEGIN(cls, gc::Object)
            INITIALIZER(cls, GitRepository, initialize);
            ADD_METHOD(cls, GitRepository, setup);
            ADD_METHOD(cls, GitRepository, shutdown);
            ADD_METHOD(cls, GitRepository, getPath);
            ADD_METHOD(cls, GitRepository, isOpen);
            ADD_METHOD(cls, GitRepository, localID);
            ADD_METHOD(cls, GitRepository, highID);
            ADD_METHOD(cls, GitRepository, cloneFromRemote);
            ADD_METHOD(cls, GitRepository, fetch);
            ADD_METHOD(cls, GitRepository, checkout);
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_GIT_H
