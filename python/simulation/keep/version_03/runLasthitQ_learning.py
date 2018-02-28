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

state_size = 2
action_size = 2
env_low = [0, 0]
env_high = [1, 1.2]
table_size = [40,40]

agent = Q_Agent(state_size, action_size,
                env_low, env_high, table_size)

env = LasthitEnvironment()

# for plot graph
episodesMean = []
scoreTemp = []
scoresMean = []
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
        agent.update_table(state, action, reward, new_state, done)
        
#        if  episode % 1000 == 0:
#            writer.writerow([state.tolist(), action, reward, new_state.tolist(), done])
            
        rewardAll += reward        
        state = new_state
        
        if done:

            rewardAllTemp = 0
            if rewardAll > 0:
                rewardAllTemp = 1
                
            scoreTemp.append(rewardAllTemp)
            
            
            if episode % 100 == 0:                
#                file.flush()
                episodesMean.append(episode/100)
                scoresMean.append( np.sum( scoreTemp ) )
            
                print("episode:",episode,"reward:",rewardAll,"len state:",len(agent.Q_table.keys()))
#          
                scoreTemp = []
                
            if episode % 3000 == 0:
                pylab.plot(episodesMean,scoresMean, 'b')
                pylab.savefig("./save_graph/image.png")
                
#                agent.model.save_weights("./testLasthit.h5")
            
            break
