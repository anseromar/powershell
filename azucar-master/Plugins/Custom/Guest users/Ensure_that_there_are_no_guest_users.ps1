#Sample skeleton PowerShell plugin code
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

            [Parameter(Mandatory=$false, HelpMessage="Save message in log file")]
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

        $Section = $AzureObject.AzureSection

        #Retrieve instance
        $Instance = $AzureObject.Instance
        #Retrieve Azure Resource Management Auth
        $RMAuth = $AzureObject.AzureConnections.ResourceManager
        $AzureVMConfig = $AzureObject.AzureConfig.AzureVM
    }
    Process{
        $GuestUsers = New-Object System.Collections.ArrayList
        
        $PluginName = $AzureObject.PluginName
        $AADConfig = $AzureObject.AzureConfig.AzureActiveDirectory
        $Section = $AzureObject.AzureSection
        Write-AzucarMessage -WriteLog $WriteLog -Message ($message.AzucarADUsersTaskMessage -f $bgRunspaceID, $PluginName, $AzureObject.TenantID) `
                                -Plugin $PluginName -IsHost -Color Green
        #Retrieve instance
        $Instance = $AzureObject.Instance
        #Retrieve Azure Active Directory Auth
        $AADAuth = $AzureObject.AzureConnections.ActiveDirectory
        #Get users
        $AllUsers = Get-AzSecAADObject -Instance $Instance -Authentication $AADAuth -Objectype "users" `
                                       -APIVersion $AADConfig.APIVersion -Verbosity $Verbosity -WriteLog $WriteLog
        foreach($User in $AllUsers){
            if ($User.userType -eq "Guest"){
                $GuestUsers.Add("["+$User.displayName+"]") > $null
            }
        }
        $ReturnValue = [PSCustomObject]@{Name='Guest users';number=$GuestUsers.Count}
    }
    End{
        if($ReturnValue){
            #Work with SyncHash
            $SyncServer.$($PluginName)=$ReturnValue
            $ReturnValue.PSObject.TypeNames.Insert(0,'AzureRM.NCCGroup.GuestuUsers')
            #Create custom object for store data
            $MyVar = New-Object -TypeName PSCustomObject
            $MyVar | Add-Member -type NoteProperty -name Section -value $Section
            $MyVar | Add-Member -type NoteProperty -name Data -value $ReturnValue
            #Add data to object
            if($MyVar){
                $ReturnPluginObject | Add-Member -type NoteProperty -name geust_users -value $MyVar
            }
        }
        else{
            Write-AzucarMessage -WriteLog $WriteLog -Message ($message.AzureADGeneralQueryEmptyMessage -f "Ensure_that_there_are_ni_geust_users Plugin", $AzureObject.TenantID) `
                                -Plugin $PluginName -Verbosity $Verbosity -IsWarning
        }
    }