#!/bin/bash

## go find the sample data in samplesBAK/ and update it in samples/



# blocks
#name="samples-blocks_cylinders-4-flat_20000_None_None_CubeSpaceAE_AMA4Conv_kltune2-top5"

# lightsout digital
#name="samples-lightsout_digital_5_5000_None_None_CubeSpaceAE_AMA4Conv_kltune2-top5"

# lightsout twisted
name="samples-lightsout_twisted_5_5000_None_None_CubeSpaceAE_AMA4Conv_kltune2-top5"

# puzzle mandrill
#name="samples-puzzle_mandrill_4_4_20000_None_None_CubeSpaceAE_AMA4Conv_kltune2-top5"

# puzzle mnist
#name="samples-puzzle_mnist_3_3_5000_None_None_CubeSpaceAE_AMA4Conv_kltune2-top5"

# sokoban
#name="samples-sokoban_sokoban_image-20000-global-global-2-train_20000_None_None_CubeSpaceAE_AMA4Conv_kltune2-top5"

cd samplesBAK

tar -xf $name.tar.bz2

new_name=$(echo $name | sed 's/samples-//' | sed 's/-top5//')

new_name_bis=$(echo $name | sed 's/_None_None//' | sed 's/samples-//' | sed 's/-top5//')

cd samples

mv $new_name $new_name_bis

cp -r $new_name_bis ../../samples/

cd ../

rm -rdf samples



#mv samples/$name $new_name

# mv $new_name samples/