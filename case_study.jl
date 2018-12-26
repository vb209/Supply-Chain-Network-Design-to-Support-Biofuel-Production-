using JuMP, Gurobi, CSVFiles, DataFrames, CSV
m = Model(solver = GurobiSolver(MIPGap=0.05)) #model definition


dir1 = "C:/Users/pbudh/Desktop/CLemson Sem_01/Engineering Optimization and Application/Extra Credit Work/Data/TX_suppliers.csv"
dir1_data = CSV.read(dir1)
s1 = nrow(dir1_data)

dir2 = "C:/Users/pbudh/Desktop/CLemson Sem_01/Engineering Optimization and Application/Extra Credit Work/Data/TX_hubs.csv"
dir2_data = CSV.read(dir2)
s2 = nrow(dir2_data)

dir3 = "C:/Users/pbudh/Desktop/CLemson Sem_01/Engineering Optimization and Application/Extra Credit Work/Data/TX_plants.csv"
dir3_data = CSV.read(dir3)
s3 = nrow(dir3_data)

# Parameters-Definition
loc1 = "C:/Users/pbudh/Desktop/CLemson Sem_01/Engineering Optimization and Application/Extra Credit Work/Data/TX_roads.csv"
#CSV.read(loc1) #reads the roads.csv file
loc_data1 = DataFrame(load(loc1)) #stores the roads.csv file in "loc_data1"
cost_ch= permutedims(reshape(loc_data1[1:end, :cost], s1, s2), (1,2)) #reshape function returns matrix and stores it in "cost_ch"

loc2 = "C:/Users/pbudh/Desktop/CLemson Sem_01/Engineering Optimization and Application/Extra Credit Work/Data/TX_railroads.csv"
loc_data2 = DataFrame(load(loc2))
cost_hp= permutedims(reshape(loc_data2[1:end, :cost], s2, s3), (1,2))

#supply= permutedims(reshape(dir1_data[1:end, Supply], s1, 1), (1,2))
inv_hub = 3476219 #investment cost of the hub
inv_ref = 130956797 #investment cost of the bio-refinery
cost_train = 3066792 #train loading/unloading cost
load_train = 338000 #train loading/unloading capacity
out_scr = 1000 #outsourcing cost per Mg
conv_yld = 232 #conversion yeild liters/Mg
demand_tot = 1476310602 #Total demand in liters
hub_cap = 300000 #hub capacity
plant_cap = 655447.004 #plant capacity

# End of Parameters-Definition

# Decision Variable Declaration

@variable(m, x[1:s1,1:s2]>=0) #Xij,mass from county to hub
@variable(m, y[1:s2,1:s3]>=0) #Yjk mass from hub to biorefinery
@variable(m, p[1:s2], Bin) #Pj is the binary variable if hub is open
@variable(m, q[1:s3], Bin) #Qk is the binary variable if refinery is open
@variable(m, r[1:s2,1:s3], Bin) #Rjk is the binary variable for rail tracks
@variable(m, h>=0) #imported supply h value from 0 to demand dk=6363408

#End of Decision Variable Declaration

#Objective function

@objective(m, Min, sum(x[i,j]*cost_ch[i,j] for i=1:s1,j=1:s2) + sum(y[j,k]*cost_hp[j,k] for j=1:s2,k=1:s3) + sum(cost_train*r[j,k] for j=1:s2,k=1:s3) + sum(p[j] for j=1:s2)*inv_hub + sum(q[k] for k = 1:s3)*inv_ref + out_scr*h)

#End of objective function

#Constraints Definition

@constraint(m, [i = 1:s1], sum(x[i,j] for j = 1:s2)<= dir1_data[i,:Supply]) #Supply capacity constraint
@constraint(m, [j = 1:s2], sum(x[i,j] for i = 1:s1)<= hub_cap*p[j]) #hub capacity constraint
@constraint(m, [k = 1:s3], sum(y[j,k] for j = 1:s2)<= plant_cap*q[k]) #plant capacity constraint
@constraint(m, sum(sum(y[j,k] for k = 1:s3) for j = 1:s2) + h == demand_tot/conv_yld) #demand constraint
@constraint(m, [j = 1:s2], sum(x[i,j] for i = 1:s1) == sum(y[j,k] for k = 1:s3)) #flow balance constraint
@constraint(m, [j = 1:s2, k = 1:s3], y[j,k] <= load_train*r[j,k]) #train constraint

#end of constraint definition


status = solve(m)
hubs = getvalue(p)
for j in 1:s2
       if hubs[j]==1
       println("hubs[$j]=",hubs[j])
       else
       end
       end
plants = getvalue(q)
for k in 1:s3
    if plants[k]==1
    println("plants[$k]=",plants[k])
else
end
end
rail_tracks = getvalue(r)
for j in 1:s2
    for k in 1:s3
    if rail_tracks[j,k] == 1
        println("rail_tracks[$j,$k]",rail_tracks[j,k])
    else
    end
    end
end
outsourced_mass = getvalue(h)
println("biomass outsourced is ", outsourced_mass)
zcost = getobjectivevalue(m)
#unit_cost_prod1 = (zcost - 3310030058.9)/3053378

tot_supply = sum(dir1_data[1:end, :Supply])
unit_cost_prod1 = (zcost - outsourced_mass)/tot_supply
