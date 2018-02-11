# -*- coding: utf-8 -*-
"""
Created on Thu Feb  8 20:42:50 2018

@author: Peachman
"""

from Q_Agent import Q_Agent
from LasthitEnvironment import LasthitEnvironment
import pylab
import csv
import numpy as np
from DQNAgent import DQNAgent
import tensorflow as tf
import keras.backend.tensorflow_backend as ktf


#def get_session(gpu_fraction=0.7):
#    gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=gpu_fraction,
#                                allow_growth=True)
#    return tf.Session(config=tf.ConfigProto(gpu_options=gpu_options))
#
#
#ktf.set_session(get_session())

state_size = 6
action_size = 2
env_low = [0, 0]
env_high = [1, 1.2]
table_size = [40,40]

agent = DQNAgent(state_size, action_size)
env = LasthitEnvironment()

# for plot graph
episodesMean = []
scoreTemp = []
scoresMean = []
errorValue = []
episodeNumber = 0

# CSV write
file = open("output.csv", "w")
writer = csv.writer(file)


for episode in range(1000000):
    state = env.reset()
    state = np.array([state])
    
    rewardAll = 0
    for i in range(500):
        action = agent.get_action(state)
#        print(state)
        new_state, reward, done, info = env.step(action) # take a random action
        new_state = np.array([new_state])
        agent.append_sample(state, action, reward, new_state, done)
        
        if episode > 2000 and  done and reward == -1 :
           writer.writerow([state.tolist(), action, reward, new_state.tolist(), done])
           file.flush()
        
#        if  episode % 1000 == 0:
#            writer.writerow([state.tolist(), action, reward, new_state.tolist(), done])
            
        rewardAll += reward        
        state = new_state
        
        if done:
            error = agent.train_model()            
            agent.update_target_model() 
            
            rewardAllTemp = 0
            if rewardAll > 0:
                rewardAllTemp = 1
                
            scoreTemp.append(rewardAllTemp)
            errorValue.append(error)
            
            
            if episode % 100 == 0:                
                
                episodesMean.append(episode/100)
                scoresMean.append( np.sum( scoreTemp ) )
            
                print("episode:",episode,"reward:",rewardAll,"error:",error)
#          
                scoreTemp = []
                
            if episode % 500 == 0:
                pylab.figure(1)
                pylab.subplot(211)
                pylab.plot(episodesMean, scoresMean, 'b')
    
                pylab.subplot(212)
                pylab.plot(errorValue, 'b')
                pylab.savefig("./save_graph/image.png")
                
                agent.model.save_weights("./testLasthit.h5")
            
            break
