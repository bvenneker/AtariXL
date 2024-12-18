with open('Chat800XL_v3_0.asm', 'r') as file, open ('new.asm','w') as newfile:
    # Read each line in the file
    for line in file:
        if (not "//" in line):
            newfile.write(line.rstrip().ljust(50) + "// \n")
            continue
        if ("//" in line):
            if(line.startswith("//")):
                newfile.write(line)
                continue
            pos=line.find("//")
            if (pos>=50):
                newfile.write(line)
                continue
            p2 = line.split("//")[1]
            p1 = line.split("//")[0]
            p1 = p1.ljust(50) + "// " + p2.strip() + "\n"
            newfile.write(p1)
            
                        
               
