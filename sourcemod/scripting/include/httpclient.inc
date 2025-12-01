#if defined _httpclient_included
  #endinput
#endif
#define _httpclient_included

/** Minimal httpclient include stub for compilation. */

enum HTTPMethod
{
    HTTPMethod_Get,
    HTTPMethod_Post,
    HTTPMethod_Put,
    HTTPMethod_Delete
};

enum HTTPStatus
{
    HTTPStatus_Continue = 100,
    HTTPStatus_SwitchingProtocols,
    HTTPStatus_Processing,
    HTTPStatus_EarlyHints = 103,

    HTTPStatus_OK = 200,
};

#pragma newdecls required

typedef function void HTTPResponseCallback(HTTPResponse response, any data);

typedef int HTTPHeader;

typedef int HTTPBody;

methodmap HTTPRequest < Handle
{
    public native HTTPRequest(const char[] url, HTTPMethod method = HTTPMethod_Post);

    property float Timeout
    {
        public native float get();
        public native void set(float value);
    }

    public native void SetHeader(const char[] name, const char[] value);
    public native void AppendHeader(const char[] name, const char[] value);
    public native void SetBody(HTTPBody body);
    public native void AppendBodyString(const char[] data);
    public native void Post(const char[] data, HTTPResponseCallback callback, any value = 0);
    public native void Send(HTTPResponseCallback callback, any value = 0);
}

methodmap HTTPResponseBody < Handle
{
    public native int ReadString(char[] buffer, int maxlen, int offset = 0);
}

methodmap HTTPResponse < Handle
{
    property HTTPStatus Status
    {
        public native HTTPStatus get();
    }

    property HTTPResponseBody Body
    {
        public native HTTPResponseBody get();
    }
}
