<<<<<<< HEAD
from flask import Flask, jsonify, request
from DQN import DQNAgent
import os
os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"   # see issue #152
os.environ["CUDA_VISIBLE_DEVICES"] = ""

app = Flask(__name__)

num_state = 6
num_action = 2
num_hidden_node = [24,24]
# m = 

dqn_agent = DQNAgent(num_state,num_action,num_hidden_node)

@app.route('/model', methods=['GET'])
def get_model():
    return jsonify(dqn_agent.get_model())

    
    # return "test"

@app.route('/update', methods=['POST'])
def update():

    dqn_agent.run(request.json)
    return jsonify(dqn_agent.get_model())


    
# @app.route('/CreepBlockAI/dump', methods=['GET'])
# def dump():
#     m.dump()
#     return jsonify({})
    
# @app.route('/CreepBlockAI/load', methods=['POST'])
# def load():
#     m.load(request.json['file'])
#     return jsonify({})
    
if __name__ == '__main__':  
=======
from flask import Flask, jsonify, request
from DQN import DQNAgent
import os
os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"   # see issue #152
os.environ["CUDA_VISIBLE_DEVICES"] = ""

app = Flask(__name__)

num_state = 6
num_action = 2
num_hidden_node = [24,24]
# m = 

dqn_save = None
checkFirst = True
dqn_agent = None

@app.route('/model', methods=['GET'])
def get_model():

    dqn_agent = test()
    return jsonify(dqn_agent.get_model())

    
    # return "test"

@app.route('/update', methods=['POST'])
def update():
    dqn_agent = test()
    # print(request.json['mem'])
    # print('update')
    dqn_agent.run(request.json)

    dqn_save = dqn_agent

    return jsonify(dqn_agent.get_model())

def test():
    global dqn_save, checkFirst , dqn_agent

    if checkFirst:
        dqn_agent = DQNAgent(num_state,num_action,num_hidden_node)
        checkFirst = False
    else:
        dqn_agent = dqn_save

    dqn_save = dqn_agent
    return dqn_agent

    
# @app.route('/CreepBlockAI/dump', methods=['GET'])
# def dump():
#     m.dump()
#     return jsonify({})
    
# @app.route('/CreepBlockAI/load', methods=['POST'])
# def load():
#     m.load(request.json['file'])
#     return jsonify({})
    
if __name__ == '__main__':  
>>>>>>> c56b3837136a2cb660127c07ef14a6d53008f2cc
    app.run(debug=True)