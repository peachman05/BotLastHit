import tensorflow as tf
import numpy as np

step = 0
session = tf.Session()

tensorboardVar = tf.Variable(0, "tensorboardVar")

pythonVar = tf.placeholder("int32", [])

update_tensorboardVar = tensorboardVar.assign(pythonVar)
#tf.scalar_summary("myVar", update_tensorboardVar)

merged = tf.merge_all_summaries()

sum_writer = tf.train.SummaryWriter('/tmp/train/c/', session.graph)

session.run(tf.initialize_all_variables())


for i in range(100):
        #_, result = session.run([update_tensorboardVar, merged])
        j = np.array(i)
        _, result = session.run([update_tensorboardVar, merged], feed_dict={pythonVar: j})
        sum_writer.add_summary(result, step)
        step += 1