package haxe.ui.loaders.image;

import haxe.io.Bytes;
import haxe.ui.assets.ImageInfo;
import haxe.ui.util.Variant;

class HttpImageLoader extends ImageLoader {
    public override function load(resource:Variant, callback:ImageInfo->Void) {
        var stringResource:String = resource;
        loadFromHttp(stringResource, function(imageInfo) {
            ToolkitAssets.instance.cacheImage(stringResource, imageInfo);
            callback(imageInfo);
        });
    }

    private function loadFromHttp(url:String, callback:ImageInfo->Void) {
        #if haxeui_no_network
        
        callback(null);
        return;
        
        #elseif js // cant use haxe.Http because we need responseType

        var request = new js.html.XMLHttpRequest();
        request.open("GET", url);
        request.responseType = js.html.XMLHttpRequestResponseType.ARRAYBUFFER;

        request.onreadystatechange = function(_) {
            if (request.readyState != 4) {
                return;
            }

            var s = try request.status catch (e:Dynamic) null;
            #if (haxe_ver >= 4)
            if (s == js.Syntax.code("undefined")) {
                s = null;
            }
            #else
            if (s == untyped __js__("undefined")) {
                s = null;
            }
            #end

            if (s != null && s >= 200 && s < 400) {
                Toolkit.assets.imageFromBytes(Bytes.ofData(request.response), callback);
            } else if (s == null) {
                callback(null);
            } else {
                #if debug

                var error:String = "Http Error #" + request.status;
                switch (s) {
                    case 12029:
                        error = "Failed to connect to host";
                    case 12007:
                        error = "Unknown host";
                    default:
                }

                trace(error);

                #end
                if (s == 0) { // Seems status = 0 is a CORS error, lets try and use a "normal" http request from the browser rather than XMLHttpRequest
                    Toolkit.assets.getImage(url, callback);
                    return;
                }
                callback(null);
            }
        }
        request.onerror = function(x) {
        }

        request.send();

        #elseif cs // hxcs bytes are wrong in haxe.Http

        var request = cs.system.net.WebRequest.Create(url);
        var buffer = new cs.NativeArray<cs.types.UInt8>(32768);
        var reader = new cs.system.io.StreamReader(request.GetResponse().GetResponseStream());
        var memStream = new cs.system.io.MemoryStream();
        var bytesRead = 0;
        while ((bytesRead = reader.BaseStream.Read(buffer, 0, buffer.Length)) > 0) {
            memStream.Write(buffer, 0, bytesRead);
        }
        reader.Close();
        Toolkit.assets.imageFromBytes(Bytes.ofData(memStream.ToArray()), callback);

        #else

        var http:haxe.Http = new haxe.Http(url);
        var httpStatus = -1;
        
        #if (haxe_ver >= 4.0)
        http.onBytes = function(data:Bytes) {
            if (data != null && data.length > 0) {
                Toolkit.assets.imageFromBytes(data, callback);
            } else {
                if (httpStatus == 301 || httpStatus == 302) { // lets follow redirects
                    #if flash

                    trace("WARNING: redirect encountered, but responseHeaders not supported, ignoring redirect");
                    callback(null); // responseHeaders doesnt exist, will not follow redirects for flash clients

                    #else

                    var location = http.responseHeaders.get("location");
                    if (location == null) {
                        location = http.responseHeaders.get("Location");
                    }
                    if (location != null) {
                        loadFromHttp(location, callback);
                    } else {
                        trace("WARNING: redirect encounters but no location header found (http status: " + httpStatus + ")");
                        callback(null);
                    }

                    #end
                } else {
                    trace("WARNING: 0 length bytes found for '" + url + "' (http status: " + httpStatus + ")");
                    callback(null);
                }
            }
        }
        
        #else
        
        http.onData = function(data:String) {
            if (data != null && data.length > 0) {
                Toolkit.assets.imageFromBytes(Bytes.ofString(data), callback);
            } else {
                if (httpStatus == 301 || httpStatus == 302) { // lets follow redirects
                    #if flash 

                    trace("WARNING: redirect encountered, but responseHeaders not supported, ignoring redirect");
                    callback(null); // responseHeaders doesnt exist, will not follow redirects for flash clients

                    #else

                    var location = http.responseHeaders.get("location");
                    if (location == null) {
                        location = http.responseHeaders.get("Location");
                    }
                    if (location != null) {
                        loadFromHttp(location, callback);
                    } else {
                        trace("WARNING: redirect encounters but no location header found (http status: " + httpStatus + ")");
                        callback(null);
                    }

                    #end
                } else {
                    trace("WARNING: 0 length bytes found for '" + url + "' (http status: " + httpStatus + ")");
                    callback(null);
                }
            }
        }
        
        #end
        
        http.onStatus = function(status:Int) {
            httpStatus = status;
        }
        
        http.onError = function(msg:String) {
            trace(msg + " (http status: " + httpStatus + ")");
            callback(null);
        }

        http.request();

        #end
    }
}