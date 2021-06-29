//
// Created by gen on 16/8/29.
//

#ifndef VOIPPROJECT_DATA_H
#define VOIPPROJECT_DATA_H


#include <memory>
#include <string>
#include <vector>
#include "Ref.h"
#include "core_define.h"

namespace gc {
    CLASS_BEGIN_NV(Data, Object)

    public:
        METHOD virtual size_t getSize() const = 0;
        METHOD virtual bool empty() const = 0;
        METHOD virtual void close() = 0;
        virtual size_t read(void *chs, size_t size, size_t nitems) = 0;
        virtual b8_vector readAll();
        METHOD virtual void seek(size_t seek, int) {}
        METHOD virtual std::string text();
    
        METHOD static Ref<Data> fromString(const std::string &str);

    protected:
        ON_LOADED_BEGIN(cls, Object)
            ADD_METHOD(cls, Data, getSize);
            ADD_METHOD(cls, Data, empty);
            ADD_METHOD(cls, Data, close);
            ADD_METHOD(cls, Data, text);
            ADD_METHOD(cls, Data, seek);
            ADD_METHOD(cls, Data, fromString);
        ON_LOADED_END
    CLASS_END

    CLASS_BEGIN_N(BufferData, Data)

        size_t size = 0;
        void *b_buffer = NULL;
        size_t offset = 0;
        bool retain;

    public:
        typedef int RetainType;
        enum {
            Ref,
            Copy,
            Retain
        };
    
        _FORCE_INLINE_ virtual size_t getSize() const {return size;}
        _FORCE_INLINE_ virtual const void *getBuffer() { return b_buffer;}
        _FORCE_INLINE_ virtual bool empty() const {
            return !(b_buffer && size);
        }
        _FORCE_INLINE_ virtual void close() {
        }
        virtual size_t read(void *chs, size_t size, size_t nitems);
        virtual void seek(size_t seek, int type);

        _FORCE_INLINE_ BufferData() {}
        METHOD void initialize(void* buffer, long size, RetainType retain = Copy);
        ~BufferData() {
            if (retain && b_buffer) {
                free(b_buffer);
            }
        }

    protected:
        ON_LOADED_BEGIN(cls, Data)
            INITIALIZER(cls, BufferData, initialize);
        ON_LOADED_END

    CLASS_END
    
    
    CLASS_BEGIN_N(FileData, Data)
        FILE *file;
    
    public:
        virtual size_t getSize() const;
        virtual bool empty() const {
            return !file;
        }
        virtual void close() {
            if (file) {
                fclose(file);
                file = NULL;
            }
        }
        virtual size_t read(void *chs, size_t size, size_t nitems);
        virtual b8_vector readAll();
    
        FileData() : file(NULL) {}

        ~FileData() {
            close();
        }
        METHOD _FORCE_INLINE_ void initialize(const char *path) {
            file = fopen(path, "r");
        }
    
    protected:
        ON_LOADED_BEGIN(cls, Data)
            INITIALIZER(cls, FileData, initialize);
        ON_LOADED_END
    CLASS_END

    CLASS_BEGIN_N(MultiData, Data)

        size_t offset = 0;
        b8_vector buffer;
    public:
        virtual size_t getSize() const {return buffer.size();}
        virtual bool empty() const {
            return !buffer.empty();
        }
        virtual void close() {
        }
        virtual size_t read(void *chs, size_t size, size_t nitems);
        virtual b8_vector readAll() {
            return buffer;
        }
        size_t write(uint8_t *buf, size_t size, size_t nitems);

    CLASS_END
}


#endif //VOIPPROJECT_DATA_H
