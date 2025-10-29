var DSP_CSP_R53 = NewDnsProvider("csp_r53");
var REG_CSP_R53 = NewRegistrar("csp_r53");
var REG_NONE = NewRegistrar("none");

var EXT_PROXY_IPV4 = '149.28.117.193'

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

function EXT_PROXY_ADDR(name) {
  return [
    A(name, EXT_PROXY_IPV4, TTL(60)),
  ]
}

var EXT_PROXY = [
  EXT_PROXY_ADDR('@'),
  EXT_PROXY_ADDR('www')
]

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
  , FORWARDEMAIL("corastreetpress.com", "aTYtp07XSX")
  , EXT_PROXY
)
D("corastreetpress.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , NO_EMAIL
)

D("bugsplat.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(86400)
  , FORWARDEMAIL("bugsplat.org", "AJkYGJl3cC")
  , EXT_PROXY
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
  , EXT_PROXY_ADDR('ord2')
  , EXT_PROXY
)


D("docverter.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , NO_EMAIL
)
D("docverter.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , NO_EMAIL
  , CNAME('c', 'docverter-demo.herokuapp.com.')
 )
D("docverter.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , NO_EMAIL
)

D("payola.io", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , NO_EMAIL
  , EXT_PROXY
)

D("masteringmodernpayments.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , NO_EMAIL
  , EXT_PROXY
)
D("masteringmodernpayments.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , NO_EMAIL
  , EXT_PROXY
)
D("masteringmodernpayments.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , NO_EMAIL
)
D("mstr.mp", REG_NONE
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , NO_EMAIL
)

D("handleyourbusiness.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , NO_EMAIL
)

D("pkn.me", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , CNAME('po', 'subspace.bugsplat.info.', TTL(300))
  , NO_EMAIL
  , EXT_PROXY
)

D("keen.land", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(30)  
  , CNAME('pm-bounces', 'pm.mtasv.net.')
  , FORWARDEMAIL("keen.land", "I1IEohSKaQ")
  , TXT('20211126004422pm._domainkey', 'k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCT0mQS8NXz+lpm9x+LDHGqm/Mhb/eLFsmuzxdYmzFOQgTaB9qBqKWb7+SNghH4J4id4i5MjfBXwj0EwVYD5IMBlnGtNYWuJlHf2E8EdjkQfee17bCYdhifoo91VCNOvqil9abzib551Jluqk251SHJTESV+qaOygLARWPeOsDFKQIDAQAB')
  , A("omada", "10.73.95.4")
  , A("protect", "10.73.95.42")
  , A("infra-git", "10.73.95.46")
  , A("zwave-shed", "10.73.95.4")
  , A("zwave-office", "10.73.95.4")
  , A("zwave-house", "10.73.95.4")
  , A("zwave-garage", "10.73.95.4")
  , A("zigbee-house", "10.73.95.4")
  , A("zigbee-office", "10.73.95.4")
  , A("@", "10.73.95.4")
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
  , EXT_PROXY
  , FORWARDEMAIL("eni889.net", "gaII8h5ZAr")
)
D("eni889.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , FORWARDEMAIL("eni889.org", "7wkRX7gBDO")
)
D("eni889.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , FORWARDEMAIL("eni889.com", "nLYU16rHbE")
)
D("emilynieset.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , FORWARDEMAIL("emilynieset.com", "fmxic58jns")
)
D("emilynieset.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , FORWARDEMAIL("emilynieset.net", "X9ck2l9OGN")
)
D("emilynieset.org", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , FORWARDEMAIL("emilynieset.org", "T2rCHy3meR")
)
D("fucktimezones.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , EXT_PROXY
  , NO_EMAIL
)
D("okapi.io", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , FORWARDEMAIL("okapi.io", "4rZQNA0rGX")
  , EXT_PROXY
)
D("zrail.net", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , NO_EMAIL
  , TXT('_atproto', 'did=did:plc:4tdje2f3mnmrxjidmu7mekf5')
  , EXT_PROXY
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
  , EXT_PROXY
)
D("petekeen.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , NO_EMAIL
  , EXT_PROXY
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
  , TXT('fe-b375ce025c._domainkey', 'v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC4tm6HJ16oMaMtiuHINNIa2RnsQ5Um5xXGmgUzmbFNgQ8CicMx/nW+MiF5uB3ianG5eADrYSWUsnvlOmvxJD5Xy1BL2eOAtJ2IWL1GEtstVRIAhdrXaQlVKo5s/8we1s8n6zJSsGSZJUgv9LRv04NSbgahKsL+mD5s/3IEbJF2fwIDAQAB;')
  , TXT('_dmarc', 'v=DMARC1; p=none; pct=100; rua=mailto:dmarc-65d8079eb3fe9f23d8948a5e@forwardemail.net;')
  , EXT_PROXY_ADDR('vmsave')
  , EXT_PROXY
)
D("peterkeen.com", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , NO_EMAIL
  , EXT_PROXY
)

D("wrought.io", REG_CSP_R53
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , EXT_PROXY
  , NO_EMAIL
 )

D("gulfse.cx", REG_NONE
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , EXT_PROXY
  , NO_EMAIL
 )

D("golfse.cx", REG_NONE
  , DnsProvider(DSP_CSP_R53)
  , DefaultTTL(60)
  , EXT_PROXY
  , NO_EMAIL
 )
