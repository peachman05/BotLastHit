# -*- coding: utf-8 -*-
"""
Created on Thu Feb  8 20:13:36 2018

@author: Peachman
"""

import random
import numpy as np

class Q_Agent:
    
    def __init__(self, state_size, action_size, env_low, env_high, table_size):        
        # if you want to see Cartpole learning, then change to True
        self.render = False
        self.load_model = False

        # get size of state and action
        self.state_size = state_size
        self.action_size = action_size
        
        # length state
        self.env_low = np.array(env_low)
        self.env_high = np.array(env_high)
        self.table_size = np.array(table_size)        
        self.env_div = (self.env_high - self.env_low) / self.table_size
        
        # These are hyper parameters for the DQN
        self.discount_factor = 0.8
        self.learning_rate = 0.001
        self.epsilon = 1.0
        self.epsilon_decay = 0.999
        self.epsilon_min = 0.01
        
        # Table
        self.Q_table = {}

        if self.load_model:
            pass
        
    def get_action(self, obs):
        if np.random.rand() <= self.epsilon:
            return random.randrange(self.action_size)
        else:
            state = self.obs_to_state(obs) 
            return np.argmax(self.Q_table[state])
        
            
    def obs_to_state(self,obs):
        """ Maps an observation to state """
        np_obs = obs[0]
        state = tuple( np.floor( (np_obs - self.env_low)/self.env_div ).tolist() )

        if  state not in self.Q_table:
            self.Q_table[state] = [0]*self.action_size
            
        return state
    
    def update_table(self, obs, action, reward, next_obs, done):
        state = self.obs_to_state(obs) 
        next_state = self.obs_to_state(next_obs) 
        
#        if done:
#            self.Q_table[state][action] = reward
#        else:
        predict = self.Q_table[state][action]
        target = reward + self.discount_factor *  np.max(self.Q_table[next_state])
        loss = target - predict
        self.Q_table[state][action] = self.Q_table[state][action] + self.learning_rate * loss
            
        
        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay
            
        
    
