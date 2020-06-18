#Plugin extract Directoryroles from Azure AD
#https://docs.microsoft.com/en-us/azure/active-directory/active-directory-assign-admin-roles
[cmdletbinding()]
    Param (
            [Parameter(HelpMessage="Background Runspace ID")]
            [int]
            $bgRunspaceID,

            [Parameter(HelpMessage="Not used in this version")]
            [HashTable]
            $SyncServer,

            [Parameter(HelpMessage="Azure Object with valuable data")]
            [Object]
            $AzureObject,

            [Parameter(HelpMessage="Object to return data")]
            [Object]
            $ReturnPluginObject,

            [Parameter(HelpMessage="Verbosity Options")]
            [System.Collections.Hashtable]
            $Verbosity,

            [Parameter(Mandatory=$false, HelpMessage="Save exception in log file")]
	        [Bool] $WriteLog

        )
    Begin{
       
        #Import Azure API
        $LocalPath = $AzureObject.LocalPath
        $API = $AzureObject.AzureAPI
        $Utils = $AzureObject.Utils
        . $API
        . $Utils

        #Import Localized data
        $LocalizedDataParams = $AzureObject.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Import Global vars
        $LogPath = $AzureObject.LogPath
        Set-Variable LogPath -Value $LogPath -Scope Global
    }
    Process{
        $PluginName = $AzureObject.PluginName
        $AADConfig = $AzureObject.AzureConfig.AzureActiveDirectory
        $Section = $AzureObject.AzureSection
        # Should be a Write-AzucarMessage

        $Instance = $AzureObject.Instance
        #Retrieve Azure Active Directory Auth
        $AADAuth = $AzureObject.AzureConnections.ActiveDirectory
        
        $PrivilegedUsersWithoutMFA = @()

        $AllUsers = Get-AzSecAADObject -Instance $Instance -Authentication $AADAuth `
                                       -Objectype "users" -APIVersion $AADConfig.APIVersion -Verbosity $Verbosity -WriteLog $WriteLog
        $AllDirectoryRoles = Get-AzSecAADObject -Instance $Instance -Authentication $AADAuth `
                                       -Objectype "directoryRoles" -APIVersion $AADConfig.APIVersion -Verbosity $Verbosity -WriteLog $WriteLog
        
        Write-Host $AllUsers[0]
        Write-Host $AllDirectoryRoles[0]

        $PrivilegedUsers | ForEach-Object{
        
        $MfaAuthMethodCount = $_.StrongAuthenticationMethods.Count
                    
        #Count number of methods
        if ($MfaAuthMethodCount -eq 0) {      
            $PrivilegedUsersWithoutMFA += $PrivilegedUsers
        }

        }

    }
    End{
    }