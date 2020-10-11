from flask import Flask, request, redirect
import urllib.parse
app = Flask(__name__)


@app.route('/')
def hello():
    return "Hello World!"


@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def catch_all(path):
    return redirect("http://10.0.0.1/?" + urllib.parse.urlencode({'orig_url': request.url}))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
