global function translatorSettings_Init

void function translatorSettings_Init(){
	ModSettings_AddModTitle( "^FFFFFF00[CT] ^5290F500Chat ^E6E6E600Translator" )

	ModSettings_AddModCategory( " > Config" )
	AddConVarSettingEnum(       "cv_translator_enabled",		    "Enabled", 											[ "Off", "On" ] )
	ModSettings_AddSetting(     "cv_translator_ignoredLanguages", 	"Comma-seperated list of language codes to ignore", "string" )
	ModSettings_AddSetting(     "cv_translator_targetLanguage", 	"Language code to translate to", 					"string" )
}