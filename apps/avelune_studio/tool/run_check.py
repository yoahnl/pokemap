import argparse
import datetime
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time


def processes():
    output = subprocess.check_output(
        ['ps', '-axo', 'pid=,ppid=,uid=,lstart=,command='], text=True
    )
    result = {}
    for line in output.splitlines():
        fields = line.split(None, 8)
        if len(fields) == 9:
            result[int(fields[0])] = {
                'parent': int(fields[1]),
                'uid': int(fields[2]),
                'started': ' '.join(fields[3:8]),
                'command': fields[8],
            }
    return result


def identity(value):
    return value['uid'], value['started'], value['command']


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('label')
    parser.add_argument('--reap-tests', action='store_true')
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command
    if command and command[0] == '--':
        command = command[1:]
    if not command or not args.label.replace('-', '').replace('_', '').isalnum():
        parser.error('A label and command are required')
    app = Path(__file__).resolve().parents[1]
    evidence = app.parents[1] / 'documentation/reports/avelune_studio/AS-ARC-002/evidence'
    evidence.mkdir(parents=True, exist_ok=True)
    log_path = evidence / (args.label + '.txt')
    result_path = evidence / (args.label + '.json')
    if log_path.exists() or result_path.exists():
        parser.error('Evidence label already exists; use a new label')
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    tracked = {}
    with log_path.open('w') as output:
        runner = subprocess.Popen(command, cwd=app, stdout=output, stderr=subprocess.STDOUT)
        while True:
            snapshot = processes()
            for pid, known in list(tracked.items()):
                current = snapshot.get(pid)
                if current and (current['uid'], current['started']) == (
                    known['uid'], known['started']
                ):
                    tracked[pid] = current
            if runner.pid in snapshot:
                tracked.setdefault(runner.pid, snapshot[runner.pid])
            changed = True
            while changed:
                changed = False
                for pid, info in snapshot.items():
                    parent = info['parent']
                    if parent in tracked and parent in snapshot:
                        if identity(tracked[parent]) != identity(snapshot[parent]):
                            continue
                        if pid not in tracked:
                            tracked[pid] = info
                            changed = True
            if runner.poll() is not None:
                break
            time.sleep(0.1)
    actions = []
    time.sleep(0.2)
    for pid, known in tracked.items():
        current = processes().get(pid)
        if not current or identity(current) != identity(known):
            continue
        harness = any(token in known['command'] for token in (
            'flutter_tester', 'frontend_server_aot', 'test.dart',
        ))
        if args.reap_tests and harness and current['uid'] == os.getuid():
            os.kill(pid, signal.SIGTERM)
            actions.append({'pid': pid, 'signal': 'SIGTERM', 'identity': current})
            for _ in range(20):
                if processes().get(pid) is None:
                    break
                time.sleep(0.1)
            current = processes().get(pid)
            if current and identity(current) == identity(known):
                os.kill(pid, signal.SIGKILL)
                actions.append({'pid': pid, 'signal': 'SIGKILL', 'identity': current})
    snapshot = processes()
    remaining = {
        str(pid): value for pid, value in tracked.items()
        if pid in snapshot and identity(value) == identity(snapshot[pid])
    }
    result = {
        'command': command,
        'cwd': str(app),
        'startedAt': started,
        'finishedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'exitCode': runner.returncode,
        'runnerPid': runner.pid,
        'trackedProcesses': tracked,
        'cleanup': actions,
        'remainingOwnedProcesses': remaining,
    }
    result_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(log_path.read_text()[-10000:])
    print(json.dumps({'exitCode': runner.returncode, 'log': str(log_path), 'remaining': remaining}))
    return runner.returncode


if __name__ == '__main__':
    sys.exit(main())
