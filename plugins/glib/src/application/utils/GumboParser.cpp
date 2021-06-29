//
// Created by Gen2 on 2020-01-31.
//

#include "GumboParser.h"
#include <gumbo/gumbo.h>
#include <gumbo-query/Document.h>
#include <gumbo-query/Node.h>
#include <sstream>
#include "Encoder.h"

using namespace gc;
using namespace std;

namespace gs {
    CLASS_BEGIN_N(Gumbo, Object)

        GumboOutput *output = NULL;
        friend class GumboNode;

    public:
        Gumbo() {}

        void initialize(const char* buffer, size_t len) {
            output = gumbo_parse_with_options(&kGumboDefaultOptions, buffer, len);
        }

        ~Gumbo() {
            if (output) gumbo_destroy_output(&kGumboDefaultOptions, output);
        }

    CLASS_END
}

gs::GumboNode::GumboNode(const gc::Ref<gs::Gumbo> &gumbo) {
    this->gumbo = gumbo;
}

gc::Ref<gs::GumboNode> gs::GumboNode::parse(const gc::Ref<gc::Data> &data, const char *encode) {
    if (!data) return nullptr;
    Ref<Data> buf_data;
    if (encode && strcmp(encode, "")) {
        buf_data = Encoder::decode(data, encode);
    } else {
        buf_data = data;
    }
    string buf = buf_data->text();
    data->close();
//    const char* str = (const char*)buf.data();
//    string cppstr;
//#define PRINT_SIZE 512
//    cppstr.resize(PRINT_SIZE);
//    size_t total = buf.size();
//    for (size_t i = 0; i < total; i += PRINT_SIZE) {
//        size_t  len = total - i;
//        memcpy((char *)cppstr.data(), str + i, min((size_t)PRINT_SIZE, len));
//        if (len < PRINT_SIZE) {
//            cppstr[len] = 0;
//        }
//        LOG(i, "%ld:%s", i, cppstr.c_str());
//    }
    Ref<Gumbo> gumbo(new_t(Gumbo, (const char*)buf.data(), buf.size()));
    gc::Ref<gs::GumboNode> node(new gs::GumboNode(gumbo));
    if (gumbo->output) {
        node->n = gumbo->output->root;
        return node;
    }
    return nullptr;
}

gc::Ref<gs::GumboNode> gs::GumboNode::parse2(const std::string &html) {
    Ref<Gumbo> gumbo(new_t(Gumbo, (const char*)html.data(), html.size()));
    gc::Ref<gs::GumboNode> node(new gs::GumboNode(gumbo));
    if (gumbo->output) {
        node->n = gumbo->output->root;
        return node;
    }
    return nullptr;
}

#define N ((::GumboNode *)n)

std::string gs::GumboNode::getTagName() {
    if (N->type == GUMBO_NODE_ELEMENT) {
         GumboTag tag = N->v.element.tag;
         if (tag < GUMBO_TAG_UNKNOWN) {
             return gumbo_normalized_tagname(tag);
         } else {
             string res;
             auto &original_tag = N->v.element.original_tag;
             if (original_tag.length > 1) {
                 for (int i = 1; i < original_tag.length; ++i) {
                    char ch = original_tag.data[i];
                    if ((ch >= 'a' && ch <= 'z') ||
                    (ch >= 'A' && ch <= 'Z') ||
                    (ch >= '0' && ch <= '9')) {
                        res.push_back(ch);
                    } else {
                        break;
                    }
                 }
             }
             return res;
         }
    }
    return std::string();
}

gc::Array gs::GumboNode::query(const std::string &css) {
    CNode cnode(N);
    CSelection selection = cnode.find(css);
    size_t len = selection.nodeNum();
    Array arr;
    for (int i = 0; i < len; ++i) {
        gs::GumboNode *node = new gs::GumboNode(gumbo);
        node->n = selection.nodeAt(i).node();
        arr.push_back(node);
    }
    return arr;
}

std::string gs::GumboNode::getText() {
    list<::GumboNode *> nodes;
    nodes.push_back(N);
    stringstream ss;
    bool white_space = true;

    while (nodes.size() > 0) {
        auto n = nodes.front();
        nodes.pop_front();

        switch (n->type) {
            case GUMBO_NODE_TEXT: {
                ss << n->v.text.text;
                white_space = false;
                break;
            }
            case GUMBO_NODE_WHITESPACE: {
                if (!white_space) {
                    ss << " ";
                    white_space = true;
                }
                break;
            }
            case GUMBO_NODE_ELEMENT: {
                if (!white_space) {
                    ss << " ";
                    white_space = true;
                }
                GumboVector children = n->v.element.children;
                for (int i = children.length - 1; i >= 0; --i) {
                    ::GumboNode *child = (::GumboNode *)children.data[i];
                    nodes.push_front(child);
                }
                break;
            }
        }
    }
    return ss.str();
}

size_t gs::GumboNode::childCount() {
    if (N->type == GUMBO_NODE_ELEMENT) {
        return N->v.element.children.length;
    }
    return 0;
}

Ref<gs::GumboNode> gs::GumboNode::childAt(size_t i) {
    if (N->type == GUMBO_NODE_ELEMENT) {
        if (i < N->v.element.children.length) {
            gs::GumboNode *node = new gs::GumboNode(gumbo);
            node->n = N->v.element.children.data[i];
            return node;
        }
    }
    return Ref<gs::GumboNode>::null();
}

gc::Ref<gs::GumboNode> gs::GumboNode::parent() {
    if (n) {
        gs::GumboNode *node = new gs::GumboNode(gumbo);
        node->n = N->parent;
        return node;
    }
    return Ref<gs::GumboNode>::null();
}

std::string gs::GumboNode::getAttribute(const std::string &name) {
    if (n && N->type == GUMBO_NODE_ELEMENT) {
        GumboAttribute *attr = gumbo_get_attribute(&N->v.element.attributes, name.c_str());
        if (attr && attr->value) {
            return attr->value;
        }
    }
    return string();
}

gs::GumboType gs::GumboNode::getType() const {
    return (gs::GumboType)N->type;
}