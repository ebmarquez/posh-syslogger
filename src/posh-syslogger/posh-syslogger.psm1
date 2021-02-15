enum MessageFacility {
  kern
  user
  mail
  daemon
  auth
  syslog
  lpr
  news
  uucp
  clock
  authpriv
  ftp
  ntp
  logaudit
  logalert
  cron
  local0
  local1
  local2
  local3
  local4
  local5
  local6
  local7
}

enum priority {
  Emergency
  Alert
  Critical
  Error
  Warning
  Notice
  Informational
  Debug
}

class Syslog {

  [int]$Port = 514
  
  [System.Net.IPAddress]$IPAddress
  
  [System.DateTime]$Date = $this.DateNow()

  [System.String]$Message

  [MessageFacility]$Facility = [MessageFacility]::local0

  [System.String]$AppName
  
  [System.String]$Identity = (New-Guid).Guid

  [String]AddressString() {
    return $this.IPAddress.IPAddressToString
  }

  [System.DateTime] DateNow() {
    return (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  }

  [void] SetDate([System.DateTime] $DateString) {
    $this.Date = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  }
}

$Script:Syslog = [syslog]::new()
$Script:UdpClient = New-Object -TypeName System.Net.Sockets.UdpClient

function New-Syslog {
  [OutputType([Syslog])]
  [CmdletBinding()]
  param(

    # IP address
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.Net.IPAddress]
    $IPAddress,

    # Port number
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [System.Int64]
    $port = 514,

    # Facility Name
    [Parameter(Mandatory = $false)]
    [MessageFacility]
    $FacilityType,

    # Date time
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [System.DateTime]
    $timeStamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),

    # Application Name
    [Parameter(Mandatory = $true)]
    [System.String]
    $ApplicationName,

    # Identity of the syslog job process.
    [Parameter(Mandatory = $false)]
    [System.String]
    $UniqueID
  )

  $Syslog.IPAddress = $IPAddress
  $Syslog.Port = $port
  if ($FacilityType) {
    $Syslog.Facility = $FacilityType
  }
  $Syslog.AppName = $ApplicationName

  if ($UniqueID) {
    $Syslog.Identity = $UniqueID
  }
  $UdpClient.Connect($Syslog.AddressString(), $Syslog.Port)
  
  return $Syslog
}

function Send-SyslogMessage {
  [CmdletBinding()]
  param (

    # Message that will be logged
    [Parameter()]
    [System.String]
    $Message,

    # Message logging level
    [Parameter(mandatory = $false)]
    [priority]
    $Priority = 'information'
  )

  $Syslog.Message = "{0}: {1}_{2}: {3}: {4}" -f $Priority.value__, $syslog.AppName, $syslog.Identity, $syslog.Facility , $Message
  $encoding = [System.Text.Encoding]::ASCII
  $messageToByte = $encoding.GetBytes($Syslog.Message)

  # Send the Message
  $UdpClient.Send($messageToByte, $messageToByte.Length)
}

function Get-SyslogId {
  return $syslog.Identity
}

function Set-SyslogId {
  [CmdletBinding()]
  param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $UniqueID
  )

  $syslog.Identity = $UniqueID
  Write-SyslogMessage -Message "Updated Job Identity from $($syslog.Identity)$($UniqueId)"
}

function Set-SyslogApplicationName {
  [CmdletBinding()]
  param (
    [Parameter()]
    [System.String]
    $ApplicationName
  )

  $syslog.AppName = $ApplicationName
}

function Get-SyslogApplicationName {
  return $syslog.AppName
}
