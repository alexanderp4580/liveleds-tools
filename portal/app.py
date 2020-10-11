from flask import Flask, render_template, request, redirect
import urllib.parse
import subprocess
import shlex
from threading import Thread
from time import sleep
app = Flask(__name__)

def restart():
    sleep(10)
    print("restarting")
    run_commands(["sudo reboot"])

@app.route('/submit', methods=['POST'])
def submit():
    ssid = request.form['ssid']
    password = request.form['password']
    print("Selected: ", ssid, password)

    result = run_commands([f"sudo nmcli d wifi connect {ssid} password {password}"])
    print(result)
    thread = Thread(target=restart)
    thread.start()
    print("Returning template")
    return render_template("submit.html")


@app.route('/')
def main():
    output = run_commands(["sudo iw dev wlan0 scan", "grep SSID"])
    address = run_commands(["hostname -I"])
    print(address)
    ssids_string = output["output"].split("\t")
    ssids = set()
    for ssid in ssids_string:
        split = ssid.split("SSID: ")
        if (len(split)) > 1 and split[1].strip() != "":
            ssid_name = split[1].strip()
            ssids.add(ssid_name)
    print(ssids)
    return render_template("index.html",
                           ssids=ssids,
                           address=address["output"].strip())


def run_commands(command_list, exit_on_error=True):
    process_list = list()
    previous_process = None

    for command in command_list:
        print('Executing [{}]'.format(command))

        args = shlex.split(command)
        if previous_process is None:
            process = subprocess.Popen(
                args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        else:
            process = subprocess.Popen(args,
                                       stdin=previous_process.stdout,
                                       stdout=subprocess.PIPE)
        process_list.append(process)
        previous_process = process

    last_process = process_list[-1]
    stdout, error = last_process.communicate()

    result = {}
    result['exit_code'] = last_process.returncode

    if stdout is not None:
        result['output'] = stdout.decode('utf-8')
    else:
        result['output'] = ''

    if error is not None:
        result['error'] = error.decode('utf-8')
    else:
        result['error'] = ''

    result['command'] = ' | '.join(command_list)

    if exit_on_error and last_process.returncode > 0:
        print('Error executing command [{}]'.format(result["command"]))
        print('stderr: [{}]'.format(result["error"]))
        print('stdout: [{}]'.format(result["output"]))
        exit(1)

    return result


@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def catch_all(path):
    return redirect("http://10.0.0.1/?" + urllib.parse.urlencode({'orig_url': request.url}))


if __name__ == '__main__':
    app.run(host="0.0.0.0", port=80)
