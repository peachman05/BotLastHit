import sys
import gym
import pylab
import random
import numpy as np
from collections import deque
from keras.layers import Dense
from keras.optimizers import Adam
from keras.models import Sequential
import tensorflow as tf
import csv

config = tf.ConfigProto()
config.gpu_options.allow_growth = True
session = tf.Session(config=config)


class DQNAgent:
    def __init__(self, state_size, action_size,num_hidden_node):
        # if you want to see Cartpole learning, then change to True
        self.render = False
        self.load_model = True
        
        # get size of state and action
        self.state_size = state_size
        self.action_size = action_size
        self.num_hidden_node = num_hidden_node

        # for plot graph
        self.episodesMean = []
        self.scoreTemp = []
        self.scoresMean = []
        self.episodeNumber = 0

        self.errorValue = []

        # These are hyper parameters for the DQN
        self.discount_factor = 0.99
        self.learning_rate = 0.001
        self.epsilon = 1.0
        self.epsilon_decay = 0.999
        self.epsilon_min = 0.01
        self.batch_size = 64
        self.train_start = 1000
        # create replay memory using deque
        self.memory = deque(maxlen=2000)

        # create main model and target model
        self.model = self.build_model()
        self.target_model = self.build_model()


        if self.load_model:
            print("load model")
            self.model.load_weights("weight_save.h5")

        # initialize target model
        self.update_target_model()

        # CSV write
        self.file = open("output.csv", "w")
        self.writer = csv.writer(self.file)

       

    # approximate Q function using Neural Network
    # state is input and Q Value of each action is output of network
    def build_model(self):
        model = Sequential()
        model.add(Dense(24, input_dim=self.state_size, activation='relu',
                        kernel_initializer='he_uniform'))
        model.add(Dense(24, activation='relu',
                        kernel_initializer='he_uniform'))
        model.add(Dense(self.action_size, activation='linear',
                        kernel_initializer='he_uniform'))
        model.summary()
        model.compile(loss='mse', optimizer=Adam(lr=self.learning_rate))
        return model

    # after some time interval update the target model to be same with model
    def update_target_model(self):
        self.target_model.set_weights(self.model.get_weights())

    # get action from model using epsilon-greedy policy
    def get_action(self, state):
#        print(state)
        if np.random.rand() <= self.epsilon:
            return random.randrange(self.action_size)
        else:
#            print("predict")
            q_value = self.model.predict(state)
            return np.argmax(q_value[0])

    # save sample <s,a,r,s'> to the replay memory
    def append_sample(self, state, action, reward, next_state, done):
        self.memory.append((state, action, reward, next_state, done))
        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay

    # pick samples randomly from replay memory (with batch_size)
    def train_model(self):
        if len(self.memory) < self.train_start:
            return
        batch_size = min(self.batch_size, len(self.memory))
        mini_batch = random.sample(self.memory, batch_size)

        update_input = np.zeros((batch_size, self.state_size))
        update_target = np.zeros((batch_size, self.state_size))
        action, reward, done = [], [], []

        for i in range(self.batch_size):
            update_input[i] = mini_batch[i][0]
            action.append(mini_batch[i][1])
            reward.append(mini_batch[i][2])
            update_target[i] = mini_batch[i][3]
            done.append(mini_batch[i][4])

        # print("1:",update_input)
        # print("2:",update_target)
        target = self.model.predict(update_input)
        target_val = self.target_model.predict(update_target)

        for i in range(self.batch_size):
            # Q Learning: get maximum Q value at s' from target model
            if done[i]:
                target[i][action[i]] = reward[i]
            else:
                target[i][action[i]] = reward[i] + self.discount_factor * (
                    np.amax(target_val[i]))

        # and do the model fit!
        error = self.model.fit(update_input, target, batch_size=self.batch_size,
                       epochs=10, verbose=0).history['loss']

        return np.mean(error)


    def get_model(self):
        dict_send = {}
        dict_send['weights_all'] = []
        dict_send['bias_all'] = []
        dict_send['num_input'] = self.state_size
        dict_send['num_output'] = self.action_size
        dict_send['hidden'] = self.num_hidden_node

        for layer in self.model.layers:
            dict_send['weights_all'].append(layer.get_weights()[0].tolist())

        for layer in self.model.layers:
            dict_send['bias_all'].append(layer.get_weights()[1].tolist())

        return dict_send

    def run(self, data):
        data_train = data['mem'][32:]
        # print(data_train)
        for i in data_train:
            # print(type(i))
            self.append_sample(i[0], i[1], i[2], i[3], i[4])

            # if self.episodeNumber % 10 == 0:
                # print("in")
            # self.writer.writerow(i)
                # self.file.flush()
            
        # self.file.flush()

        # print(self.memory)
        
        error = self.train_model()
        self.update_target_model()

        rewardAllTemp = 0
        if data['all_reward'] > 0:
            rewardAllTemp = 1

        self.scoreTemp.append(rewardAllTemp)
        self.errorValue.append(error)

        print("episode:",self.episodeNumber,"reward:",data['all_reward'],"error:",error)
        self.episodeNumber += 1

        if self.episodeNumber % 10 == 0:
            self.episodesMean.append(self.episodeNumber/10)
            self.scoresMean.append( np.sum( self.scoreTemp ) )
            self.scoreTemp = []

        if self.episodeNumber % 50 == 0:
            pylab.figure(1)
            # pylab.subplot(211)
            pylab.plot(self.episodesMean, self.scoresMean, 'b')

            # pylab.subplot(212)
            # pylab.plot(self.errorValue, 'b')
            
            pylab.savefig("./save_graph/image.png")

        if self.episodeNumber % 50 == 0:
            print("write")
            
            self.model.save_weights("weight_save.h5")





  