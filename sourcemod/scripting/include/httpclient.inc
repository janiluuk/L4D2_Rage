/**
 * HTTPClient Include File
 * Provides HTTP request/response functionality for SourceMod
 */

#if defined _httpclient_included
 #endinput
#endif
#define _httpclient_included

/**
 * HTTP Status Codes
 */
enum HTTPStatus
{
    HTTPStatus_Invalid = 0,
    HTTPStatus_OK = 200,
    HTTPStatus_Created = 201,
    HTTPStatus_NoContent = 204,
    HTTPStatus_BadRequest = 400,
    HTTPStatus_Unauthorized = 401,
    HTTPStatus_Forbidden = 403,
    HTTPStatus_NotFound = 404,
    HTTPStatus_MethodNotAllowed = 405,
    HTTPStatus_InternalServerError = 500,
    HTTPStatus_BadGateway = 502,
    HTTPStatus_ServiceUnavailable = 503
};

/**
 * HTTP Response Body
 */
methodmap HTTPResponseBody
{
    /**
     * Read response body as string
     */
    public native void ReadString(char[] buffer, int maxlen);
};

/**
 * HTTP Response
 */
methodmap HTTPResponse
{
    /**
     * HTTP status code of the response
     */
    property HTTPStatus Status {
        public native get();
    }
    
    /**
     * Response body
     */
    property HTTPResponseBody Body {
        public native get();
    }
};

/**
 * HTTP Request callback
 */
typedef HTTPRequestCallback = function void(HTTPResponse response, any data);

/**
 * HTTP Request
 */
methodmap HTTPRequest < Handle
{
    /**
     * Create a new HTTP request
     * 
     * @param url       URL to request
     * @return          HTTPRequest handle or null on failure
     */
    public native HTTPRequest(const char[] url);
    
    /**
     * Request timeout in seconds
     */
    property float Timeout {
        public native get();
        public native set(float value);
    }
    
    /**
     * Set a request header
     * 
     * @param name      Header name
     * @param value     Header value
     */
    public native void SetHeader(const char[] name, const char[] value);
    
    /**
     * Send GET request
     * 
     * @param callback  Callback function
     * @param data      Optional data to pass to callback
     */
    public native void Get(HTTPRequestCallback callback, any data = 0);
    
    /**
     * Send POST request
     * 
     * @param body      Request body
     * @param callback  Callback function
     * @param data      Optional data to pass to callback
     */
    public native void Post(const char[] body, HTTPRequestCallback callback, any data = 0);
    
    /**
     * Send PUT request
     * 
     * @param body      Request body
     * @param callback  Callback function
     * @param data      Optional data to pass to callback
     */
    public native void Put(const char[] body, HTTPRequestCallback callback, any data = 0);
    
    /**
     * Send DELETE request
     * 
     * @param callback  Callback function
     * @param data      Optional data to pass to callback
     */
    public native void Delete(HTTPRequestCallback callback, any data = 0);
};
