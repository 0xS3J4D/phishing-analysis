/*
   BankID smishing kit — detection rules
   Author:    0xS3J4D
   Reference: https://github.com/0xS3J4D/phishing-analysis
   Version:   1.0 (2026-11)
   License:   CC BY 4.0
   Purpose:   Hunt for this kit family in web roots, hosting accounts and kit archives.
   Note:      Built from static analysis of one sample; tune before production use.
*/

rule PHISH_Kit_BankID_NO_Telegram_PHP
{
    meta:
        description = "PHP backend of a Norwegian BankID phishing kit that exfiltrates via Telegram"
        author      = "0xS3J4D"
        date        = "2026-11-06"
        tlp         = "CLEAR"
        mitre       = "T1056.003, T1567, T1111"

    strings:
        $tg      = "api.telegram.org/bot" ascii nocase
        $step1   = "11siffer" ascii nocase
        $step2   = "6siffer" ascii nocase
        $step3   = "telefonnummer" ascii nocase
        $step4   = "personligpassord" ascii nocase
        $step5   = "bankselect" ascii nocase
        $brand   = "Bankid" ascii nocase
        $geo     = "geoiptool" ascii nocase
        $banner  = "Contact Me IF YOU NEED HELP" ascii nocase

    condition:
        filesize < 200KB and $tg and $brand and 3 of ($step*) and ($geo or $banner)
}

rule PHISH_Kit_BankID_NO_GeoFilter
{
    meta:
        description = "Geo-filter used by the BankID kit: ip-api Pro lookup allowing only NO"
        author      = "0xS3J4D"
        date        = "2026-11-06"
        mitre       = "T1480"

    strings:
        $api   = "pro.ip-api.com" ascii nocase
        $cc    = "countryCode" ascii
        $no    = "'NO'" ascii
        $sess  = "user_allowed" ascii

    condition:
        filesize < 50KB and all of them
}

rule PHISH_Kit_BankID_NO_Frontend
{
    meta:
        description = "Front-end page of the BankID kit: mobile-only gate + per-character DOM obfuscation"
        author      = "0xS3J4D"
        date        = "2026-11-06"
        mitre       = "T1027, T1656"

    strings:
        $ua      = "iPhone|iPad|iPod|Android" ascii
        $wrap1   = "<font>${letter}</font>" ascii
        $wrap2   = "<az>" ascii
        $cls     = "class-${rnd" ascii
        $css     = "authorization.feb520e19d2d6db01d95.css" ascii
        $robots  = "noindex, nofollow" ascii nocase
        $action  = "action.php" ascii

    condition:
        filesize < 300KB and $ua and $action and ($css or (1 of ($wrap*) and $cls)) and $robots
}
