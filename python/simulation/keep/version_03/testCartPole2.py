import gym
import pylab
import csv
import numpy as np
from Q_Agent import Q_Agent


state_size = 4
action_size = 2
<<<<<<< HEAD
env_low = [-2.4 , -900, -0.20943951, -900]
env_high = [ 2.4, 900,  0.20943951, 900]
table_size = [40,40,40,40]
=======
env_low = [-2.4 , -2.3, -0.20943951, -3.4]
env_high = [2.4 , 2.3, 0.20943951, 3.4]
table_size = [1000,1000,1000,1000]
>>>>>>> a7fb55f884a4455c975aa2133a5a8dd8342bc0a3

agent = Q_Agent(state_size, action_size,
                env_low, env_high, table_size)

env = gym.make('CartPole-v0')
# for plot graph
episodesMean = []
scoreTemp = []
scoresMean = []
episodeNumber = 0

# CSV write
file = open("output.csv", "w")
writer = csv.writer(file)

max2 = 0
max4 = 0

<<<<<<< HEAD
for episode in range(100000):
=======
for episode in range(80000):
>>>>>>> a7fb55f884a4455c975aa2133a5a8dd8342bc0a3
    state = env.reset()
#    state = np.array([state])
    
    rewardAll = 0
    for i in range(500):
        action = agent.get_action(state)
        
#        if state[1] > max2:
#            max2 = state[1]
#            
#        if state[3] > max4:
#            max4 = state[3]
        new_state, reward, done, info = env.step(action) # take a random action
        
        if reward == 0 and done:
            reward2 = -100
        else:
            reward2 = reward

            
            
#        new_state = np.array([new_state])
        agent.update_table(state, action, reward2, new_state, done)
        
#        if  episode % 1000 == 0:
#            writer.writerow([state.tolist(), action, reward, new_state.tolist(), done])
            
        rewardAll += reward        
        state = new_state
        
        if done:

#            rewardAllTemp = 0
#            if rewardAll > 0:
#                rewardAllTemp = 1
                
            scoreTemp.append(rewardAll)
            
            
            if episode % 100 == 0:                
#                file.flush()
                episodesMean.append(episode/100)
                scoresMean.append( np.sum( scoreTemp ) )
            
                print("episode:",episode,"reward:",rewardAll,"len state:",len(agent.Q_table.keys()))
#          
                scoreTemp = []
                
            if episode % 1000 == 0:
                pylab.plot(episodesMean,scoresMean, 'b')
                pylab.savefig("./save_graph/image.png")
                
            break

print(max2,max4)