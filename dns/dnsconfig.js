var DSP_CSP_R53 = NewDnsProvider("csp_r53");
var REG_CSP_R53 = NewRegistrar("csp_r53");
var REG_NONE = NewRegistrar("none");

var FORWARDEMAIL = function(the_domain, site_verification) {
  return [
    MX('@', 10, 'mx1.forwardemail.net.'),
    MX('@', 10, 'mx2.forwardemail.net.'),
    TXT('@', "forward-email-site-verification=" + site_verification),
    TXT('@', "v=spf1 a include:spf.forwardemail.net include:_spf.google.com ?all"),
    CNAME('fe-bounces', 'forwardemail.net.')
  ]
}

var NO_EMAIL = [
  TXT('@', 'v=spf1 -all'),
  TXT('*._domainkey', 'v=DKIM1; p='),
  TXT('_dmarc', 'v=DMARC1;p=reject;sp=reject;adkim=s;aspf=s')
]


var FLY_CERT = function(subdomain, the_domain) {
  var acme_target = the_domain + '.w128.flydns.net.';
  var acme_subdomain = "";

  if (subdomain != "@") {
    acme_target = subdomain + '.' + acme_target;
    acme_subdomain = '.' + subdomain;
  }

  var acme_cname = '_acme-challenge' + acme_subdomain;
  
  var records = [
    CNAME(acme_cname, acme_target, TTL(60))    
  ];

  if (subdomain == '@') {
    records.push(A('@', '66.241.125.38', TTL(60)));
    records.push(AAAA('@', '2a09:8280:1:8968:d249:6201:cd71:c56b', TTL(60)));
  } else {
    records.push(CNAME(subdomain, 'morning-voice-9704.fly.dev.', TTL(60)));
  }

  return records;
}

var FLY_PROXY = function(the_domain) {
  return [
    , FLY_CERT('@', the_domain)
    , FLY_CERT('www', the_domain)
  ]
}

var NULL = function(the_domain) {
  D(the_domain, REG_CSP_R53
    , DnsProvider(DSP_CSP_R53)
    , NO_EMAIL
  )
}

DEFAULTS(
  NAMESERVER_TTL("172800")
)

NULL("abigailkeen.com")
NULL("abigailkeen.net")
NULL("abigailkeen.org")
NULL("lilliankeen.com")
NULL("lilliankeen.net")
NULL("lilliankeen.org")
NULL("corastreet.com")
NULL("corastreetpress.net")
NULL("invoicewidget.org")
NULL("legendaryflavorspot.com")
NULL("receiptwidget.com")
NULL("remindlyo.com")
NULL("remindlyo.net")
NULL("stripereceipt.com")

D("corastreetpress.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , FLY_PROXY("corastreetpress.com")
  , FORWARDEMAIL("corastreetpress.com", "aTYtp07XSX")
)
D("corastreetpress.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("corastreetpress.org")
  , NO_EMAIL
)

D("bugsplat.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(86400)
  , FORWARDEMAIL("bugsplat.org", "AJkYGJl3cC")
)
D("bugsplat.info", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FORWARDEMAIL("bugsplat.info", "xgu9XHIPv7")
  , TXT('20211022134406pm._domainkey', 'k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCNXCAhmh6vbWog/rB0Vh+2UmnTr+FbpXSA2bqsc+26yC9tTdZNZJatxgobRmDnnM6j1QT6DuoWV8aejAe7UNd4zs5aeNu1iE0pYiACwptCLoYMgsq64ioNtDdhh5kTunAvEtPc97+HE8FqMdi0Vsc1QbhJmZf64eOJqZlk2jop0QIDAQAB')
  , CNAME('mancer', 'bugsplat-cancer-blog.herokuapp.com.')
  , A('mx', '71.19.146.42')
  , AAAA('mx', '2605:2700:0:3:a800:ff:fe6a:a631')
  , CNAME('pm-bounces', 'pm.mtasv.net.')
  , NS('subspace', 'ns-849.awsdns-42.net.')
  , NS('subspace', 'ns-1372.awsdns-43.org.')
  , NS('subspace', 'ns-1687.awsdns-18.co.uk.')
  , NS('subspace', 'ns-21.awsdns-02.com.')
  , CNAME('*.subspace', 'subspace.bugsplat.info.')
  , CNAME('twitter-fiction-reader', 'morning-voice-9704.fly.dev.')
  , A('vmsave-prod', '165.227.222.11')
  , CNAME('*.vmsave-prod', 'vmsave-prod.bugsplat.info.')
)


D("docverter.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("docverter.org")
  , NO_EMAIL
)
D("docverter.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("docverter.com")
  , NO_EMAIL
  , CNAME('c', 'docverter-demo.herokuapp.com.')
 )
D("docverter.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("docverter.net")
  , NO_EMAIL
)

D("payola.io", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("payola.io")
  , NO_EMAIL
)

D("masteringmodernpayments.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , NO_EMAIL
  , FLY_PROXY("masteringmodernpayments.net")
)
D("masteringmodernpayments.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , NO_EMAIL
  , FLY_PROXY("masteringmodernpayments.com")
)
D("masteringmodernpayments.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("masteringmodernpayments.org")
  , NO_EMAIL
)
D("mstr.mp", REG_NONE
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("mstr.mp")
  , NO_EMAIL
)

D("handleyourbusiness.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("handleyourbusiness.net")
  , NO_EMAIL
)

D("pkn.me", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , CNAME('po', 'subspace.bugsplat.info.', TTL(300))
  , NO_EMAIL
)

D("keen.land", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , A('@', '100.94.233.13')
  , CNAME('jellyfin', 'home.keen.land.')
  , CNAME('sonarr', 'home.keen.land.')
  , CNAME('radarr', 'home.keen.land.')
  , CNAME('bazarr', 'home.keen.land.')
  , CNAME('prowlarr', 'home.keen.land.')
  , CNAME('lidarr', 'home.keen.land.')
  , CNAME('sabnzbd', 'home.keen.land.')
  , CNAME('jellyseerr', 'home.keen.land.')
  , CNAME('unifi', 'home.keen.land.')
  , CNAME('protect', 'home.keen.land.')
  , CNAME('vouch', 'home.keen.land.')  
  , CNAME('hass', 'home.keen.land.')
  , CNAME('omada', 'home.keen.land.')
  , CNAME('genmon', 'home.keen.land.')
  , CNAME('status', 'home.keen.land.')
  , CNAME('spoolman', 'home.keen.land.')
  , CNAME('docs', 'home.keen.land.')
  , CNAME('pm-bounces', 'pm.mtasv.net.')
  , CNAME('home', 'subspace.bugsplat.info.')
  , FORWARDEMAIL("keen.land", "I1IEohSKaQ")
  , TXT('20211126004422pm._domainkey', 'k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCT0mQS8NXz+lpm9x+LDHGqm/Mhb/eLFsmuzxdYmzFOQgTaB9qBqKWb7+SNghH4J4id4i5MjfBXwj0EwVYD5IMBlnGtNYWuJlHf2E8EdjkQfee17bCYdhifoo91VCNOvqil9abzib551Jluqk251SHJTESV+qaOygLARWPeOsDFKQIDAQAB')
)

D("emilykeen.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FORWARDEMAIL("emilykeen.net", "25jjfLGWBD")
)
D("emilykeen.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FORWARDEMAIL("emilykeen.org", "ut0dgqMMRd")
)

D("eni889.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("eni889.net")
  , FORWARDEMAIL("eni889.net", "gaII8h5ZAr")
)
D("eni889.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("eni889.org")
  , FORWARDEMAIL("eni889.org", "7wkRX7gBDO")
)
D("eni889.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("eni889.com")
  , FORWARDEMAIL("eni889.com", "nLYU16rHbE")
)
D("emilynieset.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("emilynieset.com")
  , FORWARDEMAIL("emilynieset.com", "fmxic58jns")
)
D("emilynieset.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("emilynieset.net")
  , FORWARDEMAIL("emilynieset.net", "X9ck2l9OGN")
)
D("emilynieset.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("emilynieset.org")
  , FORWARDEMAIL("emilynieset.org", "T2rCHy3meR")
)
D("fucktimezones.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("fucktimezones.com")
  , NO_EMAIL
)
D("okapi.io", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FLY_PROXY("okapi.io")
  , FORWARDEMAIL("okapi.io", "4rZQNA0rGX")
)
D("zrail.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , NO_EMAIL
  , TXT('_atproto', 'did=did:plc:4tdje2f3mnmrxjidmu7mekf5')
  , FLY_PROXY("zrail.net")
)
D("keenfamily.us", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FORWARDEMAIL("keenfamily.us", "430yxHlkch")
  , TXT('20211217201245pm._domainkey', 'k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCPnFmPYBI9IjFbnk2LTL10ewjzcuI9v/gMQAsM9pnQatLWgDCBP3D8ix7ncsdGF4512PKqVrTBfmkeih4lwqD8DnAQuxhl0Hbdh+8k3Lmdrz+1nYh3NBWcR/15L6npiBVBjYWA9rhiXGLb2HeXAP6Wtt4xzcs91gtP1JtVRM0d7QIDAQAB')
  , TXT('fe-59b325ea47._domainkey', 'v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDTV4LfZuI8Jklvvdn0b9pd/kQPB1nE/guK4IoDyogYWTVGBh6oFiQPuYqf7c+lkmeoudKFBmkHOLBeLkFJg6iirVcliiG2MhV85hmp9HELbPYbOla/n6+WnhZxhEAU8gqQxvsdVt7s7U8UmNBFZk7IChlmxmZCifQEjM7rGr9wgQIDAQAB;')
  , TXT('_dmarc', 'v=DMARC1; p=reject; pct=100; rua=mailto:dmarc-662af3810d65e264380ae343@forwardemail.net;')

  , CNAME('pm-bounces', 'pm.mtasv.net.')
  , CNAME('photos', 'domains.smugmug.com.')
)


D("petekeen.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , NO_EMAIL
)
D("petekeen.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , NO_EMAIL
)
D("petekeen.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FORWARDEMAIL("petekeen.net", "fuPmK4gujh")
  , TXT('20201003005117pm._domainkey', 'k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCMbQU+8puMEHP7qXZt05jqUKsyjtFyE57ITqAaHzQCaeBDV+H/SIje6ByHIKHr8kC3TVWjEdCL/u8kqu4WNmVzFntF86M3kDCoQYjnZZ2PaWjgBNqqT93K6E6hCH5IXiosFRVoPgPvKIPYmLeIJ6AbPATmIjiTXa1viETdxj0p5QIDAQAB')
  , TXT('payments', 'stripe-verification=76a4cbe34c2736b78576af47097a8387e4aaa8e472410e40442bd7a5f588a04d')
  , CNAME('3bxsa2qsh4zwv2c6lts7pdndp5x4kj2v._domainkey.payments', '3bxsa2qsh4zwv2c6lts7pdndp5x4kj2v.dkim.custom-email-domain.stripe.com.')
  , CNAME('gtc2zes6wvv6oqizh47472nvtav6e6gd._domainkey.payments', 'gtc2zes6wvv6oqizh47472nvtav6e6gd.dkim.custom-email-domain.stripe.com.')
  , CNAME('lgsqupibbuwrqwic5dc3papl536jr7ho._domainkey.payments', 'lgsqupibbuwrqwic5dc3papl536jr7ho.dkim.custom-email-domain.stripe.com.')
  , CNAME('middg7h2z7ix2ome46bttaflfpwsyi2s._domainkey.payments', 'middg7h2z7ix2ome46bttaflfpwsyi2s.dkim.custom-email-domain.stripe.com.')
  , CNAME('o5gykeaiijwtq4obymuowaj7vzcneam2._domainkey.payments', 'o5gykeaiijwtq4obymuowaj7vzcneam2.dkim.custom-email-domain.stripe.com.')
  , CNAME('umnpldf5lhmrtfvihzorth4w636fk6de._domainkey.payments', 'umnpldf5lhmrtfvihzorth4w636fk6de.dkim.custom-email-domain.stripe.com.')
  , CNAME('bounce.payments', 'custom-email-domain.stripe.com.')
  , CNAME('pm-bounces', 'pm.mtasv.net.')
  , FLY_CERT('vmsave', 'petekeen.net')
  , FLY_CERT('stage', 'petekeen.net')

  , TXT('fe-b375ce025c._domainkey', 'v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC4tm6HJ16oMaMtiuHINNIa2RnsQ5Um5xXGmgUzmbFNgQ8CicMx/nW+MiF5uB3ianG5eADrYSWUsnvlOmvxJD5Xy1BL2eOAtJ2IWL1GEtstVRIAhdrXaQlVKo5s/8we1s8n6zJSsGSZJUgv9LRv04NSbgahKsL+mD5s/3IEbJF2fwIDAQAB;')
  , TXT('_dmarc', 'v=DMARC1; p=none; pct=100; rua=mailto:dmarc-65d8079eb3fe9f23d8948a5e@forwardemail.net;')
)
D("peterkeen.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , FLY_PROXY("peterkeen.net")
  , NO_EMAIL
)

D("wrought.io", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , FLY_PROXY("wrought.io")
  , NO_EMAIL
)

require('public_ingress.js')
