import random
class LasthitEnvironment:
    def __init__(self):
        # if you want to see Cartpole learning, then change to True
        self.state = 1 # hp enemy
        self.action = 2 #  idle , hit
        
        self.current_state = 550
        self.max_hit = 1.2
        self.can_hit = 0
        self.can_hit_creep = [0,0,0,0]
        
    
    def step(self, action):
        
        reward = -1 
        
        done = False
        damage_hero = random.randint(15,21)
        
        if self.can_hit <= 0  and action == 1 :
#            print("hero hit")
            if self.current_state <= damage_hero :
                self.current_state  = 0
                reward = 100
                done = True
            else:
                self.current_state -= damage_hero
            
            self.can_hit = 1.2
            

        
        for i in range(4):
            if self.can_hit_creep[i] <= 0: 
#                print("creep",i,"hit")
                damage_creep = random.randint(19,23)
                self.current_state -= damage_creep
                self.can_hit_creep[i] = self.max_hit
            else:
                self.can_hit_creep[i] -= 0.1
       
        self.can_hit -= 0.1
        
        if self.current_state <= 0:
            done = True
#        print(self.current_state )
        
#        new_state = [self.current_state/550,self.can_hit,self.can_hit_creep[0],
#                     self.can_hit_creep[1],self.can_hit_creep[2],
#                     self.can_hit_creep[3]]
        new_state = [self.current_state/550,self.can_hit]
        info = None
        return new_state, reward, done, info
        
    

    def reset(self):
        self.current_state = 550
        self.can_hit = 0
        
        for i in range(4):
            self.can_hit_creep[i] = random.randint(0,self.max_hit*10)/10
        
#        return [self.current_state /550,self.can_hit,self.can_hit_creep[0],
#                     self.can_hit_creep[1],self.can_hit_creep[2],
#                     self.can_hit_creep[3]]
        return [self.current_state /550,self.can_hit]
