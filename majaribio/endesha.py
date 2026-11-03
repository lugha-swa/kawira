# endesha.py PICHA [VITUFE...] -- washa PICHA kwenye QEMU (KVM ikiwepo,
# vinginevyo TCG), bonyeza VITUFE kupitia monitor (sendkey), kisha soma
# safu ya kwanza ya VGA (0xB8000) na uichapishe kama maandishi.
import os, socket, subprocess, sys, tempfile, time

def main():
    picha, vitufe = sys.argv[1], sys.argv[2:]
    saraka = tempfile.mkdtemp()
    soketi = os.path.join(saraka, 'monitor')
    kasi = 'kvm' if os.access('/dev/kvm', os.R_OK | os.W_OK) else 'tcg'
    qemu = subprocess.Popen(
        ['qemu-system-x86_64', '-accel', kasi, '-kernel', picha, '-m', '64',
         '-display', 'none', '-monitor', f'unix:{soketi},server,nowait'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        for _ in range(200):
            if os.path.exists(soketi):
                break
            time.sleep(0.05)
        s = socket.socket(socket.AF_UNIX)
        s.connect(soketi)
        s.settimeout(2)

        def amri(maandishi):
            s.sendall((maandishi + '\n').encode())
            time.sleep(0.3)
            jibu = b''
            try:
                while True:
                    b = s.recv(65536)
                    if not b:
                        break
                    jibu += b
                    if len(b) < 65536:
                        break
            except socket.timeout:
                pass
            return jibu.decode(errors='replace')

        time.sleep(1.0 if kasi == 'kvm' else 3.0)
        amri('')
        for k in vitufe:
            amri(f'sendkey {k}')
            time.sleep(0.2)
        time.sleep(0.5)
        jibu = amri('xp /160bx 0xb8000')
    finally:
        qemu.kill()
    baiti = [int(x, 16) for mstari in jibu.splitlines()
             if mstari.strip().startswith('00') and ':' in mstari
             for x in mstari.split(':', 1)[1].split()]
    print(''.join(chr(b) if 32 <= b < 127 else ' ' for b in baiti[0::2]).rstrip())

main()
