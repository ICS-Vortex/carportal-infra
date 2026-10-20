# Contabo support evidence — intermittent TCP refused on 77.237.234.101

**Generated:** 2026-10-20 (UTC)  
**VPS:** `vmi3678082`  
**Public IPv4:** `77.237.234.101`  
**Affected names (same A record):** `ics-vortex.com`, `car.ics-vortex.com`, `api.car.ics-vortex.com`, `cms.car.ics-vortex.com`

Attach this file plus the raw logs listed in [Attachments](#attachments) to your ticket at [my.contabo.com](https://my.contabo.com) → **Support → Contact us → Submit a ticket**.

---

## Summary

From an external client (`176.104.187.244`), roughly **40–60%** of HTTPS requests to `77.237.234.101:443` fail immediately with **TCP connection refused** (~37–40 ms). Retrying often succeeds on the next attempt (same IP, same port).

On the VPS itself, nginx listens on `0.0.0.0:443` and **five consecutive** requests to the public IP succeed every time.

This points to **network / IP reachability**, not application downtime.

---

## Timestamped HTTPS probe log (external client)

| Metric | `ics-vortex.com` | `car.ics-vortex.com` |
|--------|------------------|----------------------|
| Window | 2026-10-20T15:17:17Z – 15:17:26Z | same window |
| OK | 16 | 12 |
| FAIL (connection refused) | 24 | 8 |
| Approx. fail rate | **60%** | **40%** |

**Client:** `vortex-pc` (LAN `192.168.0.102`), egress IPv4 `176.104.187.244`  
**Full line-by-line log:** `deploy/contabo-ticket-evidence-20261020.log`

Example failures (same second, alternating OK/FAIL):

```text
2026-10-20T15:17:17Z ics-vortex.com  OK    http_code=200 time_connect=0.039626
2026-10-20T15:17:17Z ics-vortex.com  FAIL  curl: (7) Failed to connect ... port 443 after 39 ms: Could not connect to server
2026-10-20T15:17:17Z ics-vortex.com  FAIL  curl: (7) Failed to connect ... port 443 after 37 ms: Could not connect to server
2026-10-20T15:17:17Z ics-vortex.com  OK    http_code=200 time_connect=0.041385
```

---

## Verbose curl (fail vs success, same target IP)

**File:** `deploy/contabo-ticket-curl-verbose-20261020.txt`

**Failed attempt** — 2026-10-20T15:18:09Z:

```text
*   Trying 77.237.234.101:443...
* connect to 77.237.234.101 port 443 from 192.168.0.102 port 34840 failed: Connection refused
* Failed to connect to ics-vortex.com port 443 after 38 ms: Could not connect to server
```

**Successful attempt** — 2026-10-20T15:18:09Z (same wall-clock second):

```text
*   Trying 77.237.234.101:443...
* SSL connection using TLSv1.3 / ...
< HTTP/2 200
```

DNS resolves to a single A record: `77.237.234.101`.

---

## Traceroute / path (external → Contabo)

**tracepath** to `77.237.234.101` — 2026-10-20T15:17:17Z:

```text
 1:  192.168.0.1
 2:  91.200.113.26
 3:  95.215.156.90
 ...
10:  213.248.67.11
11:  45.88.191.11
12:  (no reply)
13:  77.237.234.101  reached  (~40 ms)
```

**mtr** report (`mtr -4 -r -c 20 -n 77.237.234.101`) — 2026-10-20T16:17:38+0100:

```text
HOST: vortex-pc                   Loss%   Snt   Last   Avg  Best  Wrst StDev
 ...
11.|-- 45.88.191.12               0.0%    20   37.2  37.1  36.4  38.5   0.4
12.|-- ???                       100.0    20    0.0   0.0   0.0   0.0   0.0
13.|-- 77.237.234.101             0.0%    20   39.1  40.1  39.0  46.9   1.7
```

ICMP to hop 12 may be dropped; **final hop answers with 0% loss** in this sample. **TCP/443 still fails intermittently** (see probe log), which is consistent with something in front of or beside the VM refusing some connection attempts.

---

## Contrast: same IP from inside the VPS

**SSH host:** `vmi3678082` — 2026-10-20T15:17:31Z UTC

```text
Public IP (from guest): 77.237.234.101
curl https://77.237.234.101/ (Host: ics-vortex.com): 200 200 200 200 200
ss: nginx LISTEN 0.0.0.0:443 and [::]:443
```

---

## Packet capture note

A libpcap file was **not** collected from this workstation (requires root for `tcpdump`). The verbose curl output above shows **TCP connection refused at SYN time** (no TLS handshake on failed attempts).

If Contabo requests a pcap, from any Linux client with sudo:

```bash
sudo tcpdump -i any -nn 'host 77.237.234.101 and tcp port 443' -w contabo-443.pcap &
sleep 1
for i in $(seq 1 30); do curl -4 -sS -o /dev/null --connect-timeout 2 https://ics-vortex.com/ || true; done
sudo pkill tcpdump
```

---

## Attachments

| File | Description |
|------|-------------|
| `deploy/CONTABO-TICKET-EVIDENCE.md` | This summary (for ticket body or PDF export) |
| `deploy/contabo-ticket-evidence-20261020.log` | 40 + 20 timestamped `curl` probes |
| `deploy/contabo-ticket-curl-verbose-20261020.txt` | One refused + one successful verbose session |

---

## Reproduce probes (optional)

From any external machine:

```bash
for i in $(seq 1 30); do
  date -u '+%Y-%m-%dT%H:%M:%SZ'
  curl -4 -sS -o /dev/null -w " %{http_code}\n" --connect-timeout 3 https://ics-vortex.com/ || echo " FAIL"
done
```

Expected on a healthy path: 30× `200`. Observed on 2026-10-20: mixed `200` and `curl: (7) ... Connection refused`.
