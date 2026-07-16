untyped
global function translator_Init
global function translate
global function sayin

struct{
    string          endpoint            = "https://translate-pa.googleapis.com/v1/translate"
    array<string>   ignoredLanguages    = []
    string          targetLanguage      = ""
}file

void function debugPrint( string text ){
    printt( "[Translator] " + text )
}

void function translator_Init(){
    // Set config
    file.ignoredLanguages   = split( GetConVarString( "cv_translator_ignoredLanguages" ), "," )
    file.targetLanguage     = GetConVarString( "cv_translator_targetLanguage" )

    AddCallback_OnReceivedSayTextMessage( chathook )
    debugPrint( "Initialized! :-)" )
}

void function sayin( string text, string targetLanguage ){
    // Make the query parameters
    table< string, array< string > > queryParameters = {
        [ "params.client" ]        = [ "gtx" ],
        [ "dataTypes" ]            = [ "TRANSLATION" ],
        [ "key" ]                  = [ "AIzaSyDLEeFI5OtFBwYBIoK_jj5m32rZK5CkCXA" ],
        [ "query.sourceLanguage" ] = [ "auto" ],
        [ "query.targetLanguage" ] = [ targetLanguage ],
        [ "query.text" ]           = [ text ]
    }

    // Build the request struct
    HttpRequest request
    request.method          = HttpRequestMethod.GET
    request.url             = file.endpoint
    request.queryParameters = queryParameters

    void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response ) : ( text ){
        if( response.statusCode == 200 ){
            debugPrint( "Request was successful" )
        } else {
            debugPrint( "Request was successful, however a non 200 status code was returned: " + response.statusCode )
            return
        }

        table json = DecodeJSON( response.body )
        string translation = expect string( json[ "translation" ] )

        if( translation.tolower() != text.tolower() )
            GetLocalClientPlayer().ClientCommand( "say " + translation )
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure ) : (){
        debugPrint( "Request was *not* successful" )
        debugPrint( format( "[%i] Failed to send request: %s", failure.errorCode, failure.errorMessage ) )
    }

    NSHttpRequest( request, onSuccess, onFailure )
}

array ornull function translate( string text, string targetLanguage, string sourceLanguage = "auto" ){
    table state = {
        finished    = false,
        data        = null
    }

    // Make the query parameters
    table< string, array< string > > queryParameters = {
        [ "params.client" ]        = [ "gtx" ],
        [ "dataTypes" ]            = [ "TRANSLATION" ],
        [ "key" ]                  = [ "AIzaSyDLEeFI5OtFBwYBIoK_jj5m32rZK5CkCXA" ],
        [ "query.sourceLanguage" ] = [ sourceLanguage ],
        [ "query.targetLanguage" ] = [ targetLanguage ],
        [ "query.text" ]           = [ text ]
    }

    // Build the request struct
    HttpRequest request
    request.method          = HttpRequestMethod.GET
    request.url             = file.endpoint
    request.queryParameters = queryParameters

    void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response ) : ( state, text ){
        if( response.statusCode == 200 ){
            debugPrint( "Request was successful" )
        } else {
            debugPrint( "Request was successful, however a non 200 status code was returned: " + response.statusCode )
            state.finished = true
            return
        }

        table json = DecodeJSON( response.body )
        string  sourceLanguage   = expect string( json[ "sourceLanguage" ] )
        string  translation      = expect string( json[ "translation" ] )

        debugPrint( format( "[%s] %s", sourceLanguage, translation ) )

        // Dont return data (null) if the messages language is to be ignored, or the translated message is the exact same as the original
        if(
            file.ignoredLanguages.contains( sourceLanguage ) ||
            translation.tolower() == text.tolower()
        ){
            debugPrint( "Translation will be ignored" )
        } else {
            state.data = [ sourceLanguage, translation ]
        }

        state.finished = true
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure ) : ( state ){
        debugPrint( "Request was *not* successful" )
        debugPrint( format( "[%i] Failed to send request: %s", failure.errorCode, failure.errorMessage ) )

        state.finished = true
    }

    NSHttpRequest( request, onSuccess, onFailure )

    // Wait until we have a response (doesnt have to include data)
    while( !state.finished )
        wait 0

    return expect array ornull( state.data )
}

ClClient_MessageStruct function chathook( ClClient_MessageStruct ms ){
    // Dont translate if the mod is "disabled" or the message author is yourself
    if(
        !GetConVarBool( "cv_translator_enabled" ) ||
        ms.player == GetLocalClientPlayer()
    ) return ms

    // Get translation if possible
    // Dont work with failed requests, messages of the same language, or messages that are the exact same translated
    array ornull translation = translate( ms.message, file.targetLanguage )
    if( !translation )
        return ms
    expect array( translation )

    // Im really unsure how to display this
    // Currently it just puts the translation right below the original message with the source language code at the front
    ms.message += format(
        "\n[%s] %s",
        expect string( translation[0] ), // Source language
        expect string( translation[1] )  // Actual translation
    )

    return ms
}