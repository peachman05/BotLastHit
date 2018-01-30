import sys
import gym
import pylab
import random
import numpy as np
from collections import deque
from keras.layers import Dense
from keras.optimizers import Adam
from keras.models import Sequential
import dqn_append as dq
#from random import randint


class DQNAgent:
    def __init__(self, state_size, action_size):
        # if you want to see Cartpole learning, then change to True
        self.render = False
        self.load_model = False

        # get size of state and action
        self.state_size = state_size
        self.action_size = action_size

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

        # initialize target model
        self.update_target_model()

        if self.load_model:
            self.model.load_weights("./save_model/cartpole_dqn.h5")

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
        
        
        
class LasthitEnvironment:
    def __init__(self):
        # if you want to see Cartpole learning, then change to True
        self.state = 1 # hp enemy
        self.action = 2 #  idle , hit
        
        self.current_state = 300
        self.max_hit = 5
        self.can_hit = self.max_hit;
        self.can_hit_creep = [0,0,0,0]
        
    
    def step(self, action):
        
        reward = 0 
        
        done = False
#        print(action)
        if self.can_hit >= self.max_hit  and action == 1 :
            
            if self.current_state <= 6 :
                self.current_state  = 0
                reward = 1
                done = True
            else:
                self.current_state -= 6
            
            self.can_hit = 0
            
        elif self.current_state <= 0:
            done = True
#            print("end")
        
        
        
        
        for i in range(4):
            if self.can_hit_creep[i] > self.max_hit:                
                self.current_state -= random.randint(3,5)
                self.can_hit_creep[i] = 0
            else:
                self.can_hit_creep[i] += 1
       
        self.can_hit += 1
#        print(self.current_state )
        
        new_state = [self.current_state ,self.can_hit]
        info = None
        return new_state, reward, done, info
        
    

    def reset(self):
        self.current_state = 100
        self.can_hit = self.max_hit;
        
        for i in range(4):
            self.can_hit_creep[i] = random.randint(0,self.can_hit)
        
        return self.current_state, self.can_hit
        
        
agent = DQNAgent(2, 2)
env = LasthitEnvironment()

for episode in range(10000):
    state = env.reset()
    state = np.array([state])
    
    rewardAll = 0
    for i in range(500):
        action = agent.get_action(state)
        new_state, reward, done, info = env.step(action) # take a random action
#        print(agent.model.predict(state))
#        print(episode,new_state)
        new_state = np.array([new_state])
        agent.append_sample(state, action, reward, new_state, done)
        
        rewardAll += reward
        
        state = new_state
        
        if done:
#            agent.replay()
#            agent.target_update()
            
            agent.train_model()
            agent.update_target_model()
#            agent.replay()
            print("episode:", episode, "  score:", rewardAll," i:",i)
            
            break
        
     
        
        
        
        
        
        
        
        
        
        
        