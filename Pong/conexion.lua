require( "db" );
Conexion = {};
function Conexion:get()
        local json = require "json";
        local function networkListener( event )
                if ( event.isError ) then
                        print( "Network error!");
                else
                        --print ( "RESPONSE: " .. event.response );
                        local t = json.decode( event.response );

                        for i=1,#t do
                                print( t[i].username );
                        end
                end
        end

        local headers = {}

        headers["Content-Type"] = "application/x-www-form-urlencoded"
        headers["Accept-Language"] = "en-US"

        local body = "name=Juan&location=Xativa"

        local params = {}
        params.headers = headers
        params.body = body

        network.request( "http://192.168.2.227:8000/extraer", "GET", networkListener, params);
end

function Conexion:post(username, email, puntos, aux)
        local date = os.date( "%c" );
        local modelo = system.getInfo( "model" );
        local imei = system.getInfo( "deviceID" );
        local dispositivo = modelo .. "|" .. imei;

        local function postListener( event )
                if ( event.isError ) then
                        if (DB:seleccionar(puntos)) then
                                DB:insertar(0, username, email, puntos, date, dispositivo );
                        end    
                        print( "Network error!");
                else
                        print ( "RESPONSE: " .. event.response );
                        if (aux == nil) then
                                if (DB:seleccionar(puntos)) then
                                        DB:insertar(event.response, username, email, puntos, date, dispositivo );
                                end     
                        else
                                DB:actualizar(event.response, aux );
                        end
                        
                end
        end

        local headers = {}

        headers["Content-Type"] = "application/x-www-form-urlencoded"
        headers["Accept-Language"] = "en-US"

        local body = "username="..username.."&email="..email.."&puntos="..puntos.."&fecha="..date.."&dispositivo="..dispositivo;

        local params = {}
        params.headers = headers
        params.body = body

        network.request( "http://192.168.2.227:8000/insertar", "POST", postListener, params);
end 

return Conexion;