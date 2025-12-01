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

typeset HTTPResponseCallback
{
    function void (HTTPResponse response, any data);
};

typedef int HTTPHeader;

typedef int HTTPBody;

methodmap HTTPRequest < Handle
{
    public HTTPRequest(const char[] url, HTTPMethod method = HTTPMethod_Post)
    {
        return view_as<HTTPRequest>(null);
    }

    property float Timeout
    {
        public float get()
        {
            return 0.0;
        }

        public void set(float value)
        {
        }
    }

    public void SetHeader(const char[] name, const char[] value) {}
    public void AppendHeader(const char[] name, const char[] value) {}
    public void SetBody(HTTPBody body) {}
    public void AppendBodyString(const char[] data) {}
    public void Post(const char[] data, HTTPResponseCallback callback, any value = 0) {}
    public void Send(HTTPResponseCallback callback, any value = 0) {}
}

methodmap HTTPResponseBody < Handle
{
    public int ReadString(char[] buffer, int maxlen, int offset = 0)
    {
        buffer[0] = '\0';
        return 0;
    }
}

methodmap HTTPResponse < Handle
{
    property HTTPStatus Status
    {
        public HTTPStatus get()
        {
            return HTTPStatus_OK;
        }
    }

    property HTTPResponseBody Body
    {
        public HTTPResponseBody get()
        {
            return view_as<HTTPResponseBody>(null);
        }
    }
}
