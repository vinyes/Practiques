local storyboard = require "storyboard";
local myData = require "myData";
local scene = storyboard.newScene();
storyboard.purgeOnSceneChange = true;
system.activate("multitouch");
require "sqlite3";
local db;

-- conexiones sqlite para guardar puntuaciones del juego.
local path = system.pathForFile("data.db", system.DocumentsDirectory)
db = sqlite3.open( path ) ;

local fisica = require( "physics" )
fisica.start();
physics.setGravity(0, 0);
--fisica.setDrawMode("hybrid");

local tamanyo_width = display.actualContentWidth ;
local tamanyo_height = display.actualContentHeight;
-- sacar el centro de la pantalla de y
local centro_y = display.contentCenterY;
local centro_x = display.contentCenterX;
local pelota;
local timer1;
local sonido_pelota;
local sonido_pared;
local contador = 0;
local txt_crono;
local number = 0;
local minutos = 0;
local paletaSuperior;
local paletaInferior;
-- variables utilizadas para contar el número de rebotes de la pelota en la paleta.
local puntos_1 = 0;
local puntos_2 = 0;
local txt_marcador_1;
local txt_marcador_2;
-- variable utilizada para saber la dirección de la bola.
local direccion = true;

-- creación de los nombres de los jugadores
local player_uno_name;
local player_dos_name;

-- creación de los nombres de los jugadores
local player_uno;
local player_dos;

-- tiempo
local  tiempo;

-- empezar el crono del tiempo de la partida
local crono_empezado = false;

-- velocidad de la bola
local velocidad = 200;

-- comprobar si la bola ya esta pintada
local bola_pintada = false;

-- número de puntos para que termine la partida
local tantos = 5;

local posicion_linea_arriba = centro_y - (centro_y / 2) - ((centro_y / 2) / 2);
local posicion_linea_bajo = centro_y + (centro_y / 2) + ((centro_y / 2) / 2);

local function movimiento( event )
    if event.phase == "began" then
    elseif event.phase == "moved" then
        
        local y = event.y;
        local aux = y;

        if (y == paletaInferior.height / 2 or y < paletaInferior.height / 2) then
            aux = paletaInferior.height / 2;
        else
            aux = y;
        end

        if (y >= display.contentHeight - paletaInferior.height / 2) then
            aux = display.contentHeight - paletaInferior.height / 2;
        end

        event.target.y = aux;
    end

    return true
end

-- metodo utilizado para emitir un sonido cuando la bola colisiona con las tabletas de los jugadores. También utilizamos
-- el método para intercambiar las direcciones de la pelota.
local function golpeo_bola( event )
    if ( event.phase == "began" ) then
        audio.play( sonido_pelota );
        if (direccion == true) then
            direccion = false;
        else 
            direccion = true;
        end
    elseif ( event.phase == "ended" ) then

    end
end

local function cronometro()
    number = number + 1;
    if (number == 60) then
        number = 0;
        minutos = minutos + 1;
    end

    if (number < 10 and minutos == 0) then
        tiempo = minutos .. "0:0" .. number;
    end

    if (number >= 10 and minutos == 0) then
        tiempo = minutos .. "0:" .. number;
    end

    if (minutos > 0 and minutos < 10 and number < 10) then
        tiempo = "0" .. minutos .. ":0" .. number;
    end

    if (minutos > 0 and minutos < 10 and number >= 10) then
        tiempo = "0" .. minutos .. ":" .. number;
    end

    txt_crono.text = tiempo;
end

local function pintar_bola()
    if (crono_empezado == false) then
        crono_empezado = true;
        cronometro = timer.performWithDelay(1000, cronometro, 0);
    end
    local velocidad_y = math.random(-80, 80);
    -- dibujamos la pelota y la posicionamos
    if (bola_pintada == false) then
        pelota = display.newCircle( display.contentWidth / 2, centro_y, 10 );
        pelota:setFillColor( 1,1,1 );
        fisica.addBody(pelota, "dynamic", {bounce=1, density = 9.0, radius = 10});
        pelota:setLinearVelocity( velocidad, velocidad_y);

        -- evento de colisión para que suene la pelota al colisionar contra las paletas.
        sonido_pelota = audio.loadSound( "golpe_pelota.mp3" );
        pelota:addEventListener( "collision", golpeo_bola );

        bola_pintada = true;
    end
end

-- función utilizada para mostrar dialogos.
local function dialogo( event )
    if "clicked" == event.action then
        local i = event.index
        if 1 == i then

        end
    end
end

-- evento periodico que lo que hace es comporbar si hemos terminado la partida.
local function comprobacion()
    if (bola_pintada == true) then
        if (pelota.x >= display.contentHeight * 2) then
            pintar_bola();
            velocidad = 200;
            puntos_1 = puntos_1 + 1;
            bola_pintada = false;
        end

        if (pelota.x <= 0) then    
            pintar_bola();
            velocidad = -200;
            puntos_2 = puntos_2 + 1;
            bola_pintada = false;
        end
    end
  

    if (puntos_1 == tantos) then
         local tabla = {
            puntos = puntos_1; 
            jugador = player_uno_name;
            tiempo = tiempo;
        };
        myData.partida[#myData.partida + 1] = tabla;

        local tablefill =[[INSERT INTO puntuaciones VALUES (NULL, ']].. player_uno_name ..[[',']].. puntos_1 ..[[',']].. tiempo ..[['); ]]
        db:exec(tablefill)

        storyboard.gotoScene( "puntuaciones");
        timer.cancel(timer1);
    end

    if (puntos_2 == tantos) then
        local tabla = {
            puntos = puntos_2; 
            jugador = player_dos_name;
            tiempo = tiempo;
        };
        myData.partida[#myData.partida + 1] = tabla;
        
        local tablefill =[[INSERT INTO puntuaciones VALUES (NULL, ']].. player_dos_name ..[[',']].. puntos_2 ..[[',']].. tiempo ..[['); ]]
        db:exec(tablefill)

        storyboard.gotoScene( "puntuaciones");
        timer.cancel(timer1);
    end

    -- actualizamos el texto para saber el número de rebotes de los jugadores.
    txt_marcador_1.text = puntos_1;
    txt_marcador_2.text = puntos_2;
end

local function golpeo_pared( event )
    if ( event.phase == "began" ) then
        audio.play( sonido_pared );
    elseif ( event.phase == "ended" ) then
        
    end
end

-- mediante esta función lo que hacemos es crear la escena del juego.
-- añadimos cada objeto creado al group para así destruir todos los objetos cuando pasamos de escena.
function scene:createScene( event )
    local group = self.view

     -- inicializamos variables
    number = 0;
    minutos = 0;
    puntos_1 = 0;
    puntos_2 = 0;
    crono_empezado = false;

    player_uno_name = myData.name_player_one;
    player_dos_name = myData.name_player_two;

    -- mostrar información al usuario.
    local alert = native.showAlert( "Información", "Pulse sobre el fondo para que salga la bola.", { "OK" }, dialogo);

    -- quitar barra de estados
    display.setStatusBar( display.HiddenStatusBar );

    local fondo = display.newImageRect( "fondo_negro.png", 480, 320 );
    fondo.x = 240;
    fondo.y = 160;
    group:insert(fondo);

    fondo:addEventListener( "touch", pintar_bola );

    -- lo que hacemos es mostrar el texto para saber quien es cada jugador.
    player_uno = display.newText( player_uno_name, 30 , 15, native.systemFontBold, 12 );
    player_uno:setFillColor( 1, 1, 1 );
    group:insert( player_uno );

    player_dos = display.newText( player_dos_name, display.contentWidth - 30 , display.contentHeight - 15, native.systemFontBold, 12 );
    player_dos:setFillColor( 1, 1, 1 );
    group:insert( player_dos );

    -- escribimos el número de rebotes de los jugadores.
    txt_marcador_1 = display.newText( puntos_1, (display.contentWidth / 2) - 40 , 30, native.systemFontBold, 32 );
    txt_marcador_2 = display.newText( puntos_2, (display.contentWidth / 2) + 40 , 30, native.systemFontBold, 32 );
    group:insert(txt_marcador_1);
    group:insert(txt_marcador_2);

    -- dibujamos la paleta superior para que el jugador pueda parar la bola.
    paletaSuperior = display.newRect( 30, display.contentHeight / 2, 12, 70);
    paletaSuperior:setFillColor( 1, 1, 1 );
    fisica.addBody(paletaSuperior, "static", {density = 9.0});
    group:insert(paletaSuperior);

    -- dibujamos la paleta inferior para que el jugador pueda parar la bola.
    paletaInferior = display.newRect( display.contentWidth - 30, display.contentHeight / 2, 12, 70);
    paletaInferior:setFillColor( 1, 1, 1 );
    fisica.addBody(paletaInferior, "static", {density = 9.0});
    paletaInferior.name = "paletaInferior";
    group:insert(paletaInferior);

    paletaInferior:addEventListener( "touch", movimiento );
    paletaSuperior:addEventListener( "touch", movimiento );

    -- dibujamos la línea central de la pista de juego y la añadimos al grupo.
    local lineaCentral = display.newRect( centro_x, centro_y , 2, display.contentHeight);
    lineaCentral:setFillColor( 255,255,255 );
    group:insert(lineaCentral);

    -- situamos las líneas laterales de la pista.
    local  linea_arriba =  display.newRect( 0, 0, tamanyo_width * 2, 0);
    group:insert(linea_arriba);

    local  linea_bajo =  display.newRect( 0, display.contentHeight, tamanyo_width * 2, 0);
    lineaCentral:setFillColor( 255,255,255 );
    group:insert(linea_bajo);

    fisica.addBody(linea_bajo, "static", {});
    fisica.addBody(linea_arriba, "static", {});

    -- evento de colisión para que suene la pelota al rebotar contra las paredes.
    sonido_pared = audio.loadSound( "golpe_pared.mp3" );
    linea_bajo:addEventListener( "collision", golpeo_pared );
    linea_arriba:addEventListener( "collision", golpeo_pared );

    -- dibujamos el cronómetro
    txt_crono = display.newText( minutos .. "0:0" .. number, display.contentWidth / 2 + (display.contentWidth / 3), 20, native.systemFont, 18 );
    group:insert( txt_crono );
end

function scene:enterScene( event )
    local group = self.view

    -- cuando entramos en la escena arrancamos los timer. timer1 nos sirve para controlar el final del juego.
    -- cronometro para medir el tiempo de la partida.
    timer1 = timer.performWithDelay(300, comprobacion, 0);
end

function scene:exitScene( event )
    local group = self.view;
end

function scene:destroyScene( event )
    local group = self.view;
end

scene:addEventListener( "createScene", scene );
scene:addEventListener( "enterScene", scene );
scene:addEventListener( "exitScene", scene );
scene:addEventListener( "destroyScene", scene );

return scene;