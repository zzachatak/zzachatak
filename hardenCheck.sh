#!/bin/bash
# ============================================================
#  Linux System Hardening Grading Script
#  Run as root: sudo bash hardening_check.sh
#  Optionally save report: sudo bash hardening_check.sh | tee report.txt
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

PASS=0
FAIL=0
WARN=0
TOTAL=0

pass() { echo -e "  ${GREEN}[PASS]${RESET} $1"; ((PASS++)); ((TOTAL++)); }
fail() { echo -e "  ${RED}[FAIL]${RESET} $1"; ((FAIL++)); ((TOTAL++)); }
warn() { echo -e "  ${YELLOW}[WARN]${RESET} $1"; ((WARN++)); ((TOTAL++)); }
section() { echo -e "\n${CYAN}${BOLD}══════════════════════════════════════${RESET}"; echo -e "${CYAN}${BOLD}  $1${RESET}"; echo -e "${CYAN}${BOLD}══════════════════════════════════════${RESET}"; }

if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}[!] This script must be run as root. Use: sudo bash $0${RESET}"
  exit 1
fi

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   Linux Hardening Grading Script         ║"
echo "  ║   $(date '+%Y-%m-%d %H:%M:%S')                    ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# ─── 1. USER & AUTHENTICATION ───────────────────────────────
section "1. User & Authentication"

# Root login via SSH disabled
if grep -Eq "^PermitRootLogin\s+no" /etc/ssh/sshd_config 2>/dev/null; then
  pass "SSH root login is disabled"
else
  fail "SSH root login is NOT disabled (set PermitRootLogin no)"
fi

# Password authentication disabled (key-only)
if grep -Eq "^PasswordAuthentication\s+no" /etc/ssh/sshd_config 2>/dev/null; then
  pass "SSH password authentication is disabled (key-only)"
else
  warn "SSH password authentication is enabled (consider key-only auth)"
fi

# Empty password accounts
EMPTY_PASS=$(awk -F: '($2 == "" ) {print $1}' /etc/shadow 2>/dev/null)
if [[ -z "$EMPTY_PASS" ]]; then
  pass "No accounts with empty passwords"
else
  fail "Accounts with empty passwords: $EMPTY_PASS"
fi

# UID 0 accounts (only root should be UID 0)
UID0=$(awk -F: '($3 == 0) {print $1}' /etc/passwd | grep -v "^root$")
if [[ -z "$UID0" ]]; then
  pass "Only root has UID 0"
else
  fail "Non-root accounts with UID 0: $UID0"
fi

# Password max age
MAX_AGE=$(grep "^PASS_MAX_DAYS" /etc/login.defs 2>/dev/null | awk '{print $2}')
if [[ -n "$MAX_AGE" && "$MAX_AGE" -le 90 && "$MAX_AGE" -gt 0 ]]; then
  pass "Password max age is set to $MAX_AGE days (≤90)"
else
  warn "Password max age is '$MAX_AGE' — recommend ≤90 days in /etc/login.defs"
fi

# Password min length
MIN_LEN=$(grep "^minlen" /etc/security/pwquality.conf 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')
if [[ -n "$MIN_LEN" && "$MIN_LEN" -ge 12 ]]; then
  pass "Password minimum length is $MIN_LEN (≥12)"
else
  warn "Password min length is '${MIN_LEN:-not set}' — recommend ≥12 in /etc/security/pwquality.conf"
fi

# Lock after failed attempts
LOCKOUT=$(grep -E "^deny" /etc/security/faillock.conf 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')
if [[ -n "$LOCKOUT" && "$LOCKOUT" -le 5 ]]; then
  pass "Account lockout after $LOCKOUT failed attempts"
else
  warn "Account lockout not configured — set 'deny = 5' in /etc/security/faillock.conf"
fi

# ─── 2. SSH HARDENING ───────────────────────────────────────
section "2. SSH Configuration"

checks=(
  "^Protocol\s+2|SSH Protocol 2 enforced|SSH Protocol 2 NOT enforced (add: Protocol 2)"
  "^X11Forwarding\s+no|X11 Forwarding disabled|X11 Forwarding is enabled (set X11Forwarding no)"
  "^MaxAuthTries\s+[1-4]$|MaxAuthTries ≤4|MaxAuthTries > 4 or not set (recommend MaxAuthTries 3)"
  "^ClientAliveInterval\s+[0-9]|ClientAlive timeout set|ClientAlive timeout not set (add ClientAliveInterval 300)"
  "^PermitEmptyPasswords\s+no|Empty SSH passwords blocked|Empty SSH passwords allowed (set PermitEmptyPasswords no)"
  "^UsePAM\s+yes|PAM enabled for SSH|PAM not enabled (set UsePAM yes)"
)

for chk in "${checks[@]}"; do
  IFS='|' read -r pattern pass_msg fail_msg <<< "$chk"
  if grep -Eq "$pattern" /etc/ssh/sshd_config 2>/dev/null; then
    pass "$pass_msg"
  else
    warn "$fail_msg"
  fi
done

# SSH port not default
SSH_PORT=$(grep -E "^Port\s+" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
if [[ -n "$SSH_PORT" && "$SSH_PORT" != "22" ]]; then
  pass "SSH running on non-default port ($SSH_PORT)"
else
  warn "SSH running on default port 22 (consider changing)"
fi

# ─── 3. FIREWALL ────────────────────────────────────────────
section "3. Firewall"

if command -v ufw &>/dev/null; then
  UFW_STATUS=$(ufw status 2>/dev/null | head -1)
  if echo "$UFW_STATUS" | grep -qi "active"; then
    pass "UFW firewall is active"
  else
    fail "UFW is installed but NOT active (run: ufw enable)"
  fi
elif command -v firewall-cmd &>/dev/null; then
  if firewall-cmd --state 2>/dev/null | grep -qi "running"; then
    pass "firewalld is active"
  else
    fail "firewalld is installed but NOT running"
  fi
elif iptables -L -n &>/dev/null 2>&1; then
  RULES=$(iptables -L INPUT --line-numbers 2>/dev/null | grep -c "^[0-9]")
  if [[ "$RULES" -gt 2 ]]; then
    pass "iptables has active rules ($RULES INPUT rules)"
  else
    warn "iptables present but minimal rules — verify firewall policy"
  fi
else
  fail "No active firewall detected (ufw/firewalld/iptables)"
fi

# ─── 4. FILE PERMISSIONS ────────────────────────────────────
section "4. File Permissions"

file_checks=(
  "/etc/passwd|644|/etc/passwd permissions"
  "/etc/shadow|640|/etc/shadow permissions"
  "/etc/ssh/sshd_config|600|sshd_config permissions"
  "/etc/gshadow|640|/etc/gshadow permissions"
  "/boot/grub/grub.cfg|600|GRUB config permissions"
)

for fc in "${file_checks[@]}"; do
  IFS='|' read -r filepath expected_perm label <<< "$fc"
  if [[ -f "$filepath" ]]; then
    actual_perm=$(stat -c "%a" "$filepath" 2>/dev/null)
    if [[ "$actual_perm" -le "$expected_perm" ]]; then
      pass "$label is $actual_perm (≤$expected_perm)"
    else
      fail "$label is $actual_perm — should be ≤$expected_perm"
    fi
  else
    warn "$filepath not found — skipping"
  fi
done

# World-writable files (excluding /tmp, /proc, /sys, /dev)
WW_FILES=$(find / -xdev -type f -perm -0002 \
  -not -path "/proc/*" -not -path "/sys/*" \
  -not -path "/dev/*" -not -path "/tmp/*" \
  -not -path "/run/*" 2>/dev/null | head -10)
if [[ -z "$WW_FILES" ]]; then
  pass "No unexpected world-writable files found"
else
  fail "World-writable files found:\n$(echo "$WW_FILES" | sed 's/^/    /')"
fi

# SUID/SGID unusual binaries
SUID_LIST=$(find / -xdev -perm /6000 -type f \
  -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null \
  | grep -Ev "^(/usr/bin/(sudo|su|passwd|chsh|chfn|newgrp|gpasswd|mount|umount|ping|ssh-agent)|/usr/sbin|/bin/su|/usr/lib)")
if [[ -z "$SUID_LIST" ]]; then
  pass "No unusual SUID/SGID binaries found"
else
  warn "Unusual SUID/SGID binaries — review manually:\n$(echo "$SUID_LIST" | head -5 | sed 's/^/    /')"
fi

# ─── 5. KERNEL & SYSCTL ─────────────────────────────────────
section "5. Kernel Hardening (sysctl)"

sysctl_checks=(
  "net.ipv4.ip_forward|0|IP forwarding disabled"
  "net.ipv4.conf.all.send_redirects|0|ICMP redirects sending disabled"
  "net.ipv4.conf.all.accept_redirects|0|ICMP redirects acceptance disabled"
  "net.ipv4.conf.all.accept_source_route|0|Source routing disabled"
  "net.ipv4.tcp_syncookies|1|SYN cookies enabled"
  "net.ipv4.conf.all.log_martians|1|Martian packet logging enabled"
  "kernel.randomize_va_space|2|ASLR fully enabled"
  "kernel.dmesg_restrict|1|dmesg restricted to root"
  "fs.suid_dumpable|0|SUID core dumps disabled"
  "net.ipv6.conf.all.disable_ipv6|1|IPv6 disabled (if not needed)"
)

for sc in "${sysctl_checks[@]}"; do
  IFS='|' read -r key expected label <<< "$sc"
  actual=$(sysctl -n "$key" 2>/dev/null)
  if [[ "$actual" == "$expected" ]]; then
    pass "$label ($key = $actual)"
  else
    warn "$label — $key is '${actual:-not set}' (expected $expected)"
  fi
done

# ─── 6. SERVICES ────────────────────────────────────────────
section "6. Unnecessary Services"

risky_services=(
  "telnet|Telnet"
  "rsh|Remote Shell (rsh)"
  "rlogin|Remote Login (rlogin)"
  "rexec|Remote Exec (rexec)"
  "tftp|TFTP"
  "vsftpd|FTP (vsftpd)"
  "pure-ftpd|FTP (pure-ftpd)"
  "xinetd|xinetd"
  "avahi-daemon|Avahi mDNS"
  "cups|CUPS printing"
  "nfs|NFS server"
)

for svc in "${risky_services[@]}"; do
  IFS='|' read -r name label <<< "$svc"
  if systemctl is-active --quiet "$name" 2>/dev/null; then
    warn "$label service is RUNNING — disable if not needed"
  else
    pass "$label is not running"
  fi
done

# ─── 7. UPDATES & PACKAGES ──────────────────────────────────
section "7. Updates & Package Security"

# Check for pending security updates
if command -v apt &>/dev/null; then
  UPDATES=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" 2>/dev/null || echo 0)
  if [[ "$UPDATES" -eq 0 ]]; then
    pass "System is up to date (apt)"
  else
    warn "$UPDATES package update(s) available — run: apt upgrade"
  fi
elif command -v yum &>/dev/null || command -v dnf &>/dev/null; then
  PKG_MGR=$(command -v dnf || command -v yum)
  UPDATES=$($PKG_MGR check-update --quiet 2>/dev/null | grep -c "^[a-zA-Z]" || echo 0)
  if [[ "$UPDATES" -eq 0 ]]; then
    pass "System is up to date ($(basename $PKG_MGR))"
  else
    warn "$UPDATES package update(s) available"
  fi
fi

# Automatic security updates
if systemctl is-active --quiet unattended-upgrades 2>/dev/null || \
   systemctl is-active --quiet dnf-automatic 2>/dev/null || \
   systemctl is-active --quiet yum-cron 2>/dev/null; then
  pass "Automatic security updates are enabled"
else
  warn "Automatic security updates not detected (consider enabling)"
fi

# ─── 8. LOGGING & AUDITING ──────────────────────────────────
section "8. Logging & Auditing"

if systemctl is-active --quiet auditd 2>/dev/null; then
  pass "auditd (audit daemon) is running"
else
  warn "auditd is not running — install and enable: apt install auditd"
fi

if systemctl is-active --quiet rsyslog 2>/dev/null || \
   systemctl is-active --quiet syslog 2>/dev/null || \
   systemctl is-active --quiet systemd-journald 2>/dev/null; then
  pass "System logging is active"
else
  fail "No active syslog service detected"
fi

# Log file permissions
if [[ -d /var/log ]]; then
  LOG_WORLD=$(find /var/log -type f -perm -o+r 2>/dev/null | wc -l)
  if [[ "$LOG_WORLD" -eq 0 ]]; then
    pass "No world-readable log files in /var/log"
  else
    warn "$LOG_WORLD world-readable log files in /var/log"
  fi
fi

# ─── 9. APPARMOR / SELINUX ──────────────────────────────────
section "9. Mandatory Access Control"

if command -v apparmor_status &>/dev/null; then
  AA_STATUS=$(apparmor_status 2>/dev/null | grep "profiles are in enforce mode" | awk '{print $1}')
  if [[ -n "$AA_STATUS" && "$AA_STATUS" -gt 0 ]]; then
    pass "AppArmor is active with $AA_STATUS profile(s) in enforce mode"
  else
    warn "AppArmor installed but no profiles in enforce mode"
  fi
elif command -v getenforce &>/dev/null; then
  SE_STATUS=$(getenforce 2>/dev/null)
  if [[ "$SE_STATUS" == "Enforcing" ]]; then
    pass "SELinux is Enforcing"
  elif [[ "$SE_STATUS" == "Permissive" ]]; then
    warn "SELinux is Permissive — set to Enforcing in /etc/selinux/config"
  else
    fail "SELinux is Disabled"
  fi
else
  warn "Neither AppArmor nor SELinux detected — consider enabling MAC"
fi

# ─── 10. CRON & SCHEDULED TASKS ────────────────────────────
section "10. Cron & Scheduled Tasks"

CRON_PERM=$(stat -c "%a" /etc/crontab 2>/dev/null)
if [[ -n "$CRON_PERM" && "$CRON_PERM" -le 644 ]]; then
  pass "/etc/crontab permissions are $CRON_PERM"
else
  warn "/etc/crontab permissions are $CRON_PERM (recommend 644)"
fi

if [[ -f /etc/cron.allow ]]; then
  pass "/etc/cron.allow exists (cron access is whitelisted)"
else
  warn "/etc/cron.allow not found — consider restricting cron access"
fi

# ─── FINAL SCORE ────────────────────────────────────────────
echo -e "\n${BOLD}══════════════════════════════════════${RESET}"
echo -e "${BOLD}  GRADING SUMMARY${RESET}"
echo -e "${BOLD}══════════════════════════════════════${RESET}"
echo -e "  ${GREEN}PASS${RESET}  : $PASS"
echo -e "  ${YELLOW}WARN${RESET}  : $WARN"
echo -e "  ${RED}FAIL${RESET}  : $FAIL"
echo -e "  TOTAL : $TOTAL"

SCORE=$(( (PASS * 100) / TOTAL ))
echo ""
if [[ $SCORE -ge 85 ]]; then
  echo -e "  ${GREEN}${BOLD}Score: $SCORE/100 — HARDENED ✓${RESET}"
elif [[ $SCORE -ge 60 ]]; then
  echo -e "  ${YELLOW}${BOLD}Score: $SCORE/100 — NEEDS IMPROVEMENT ⚠${RESET}"
else
  echo -e "  ${RED}${BOLD}Score: $SCORE/100 — VULNERABLE ✗${RESET}"
fi
echo -e "${BOLD}══════════════════════════════════════${RESET}\n"
