def read_map(parcels_json):
    parcels = set()
    index = 0
    total_area = 0
    num_lucs = len(parcels_json)
    parcel_list = list(parcels_json)
    for i in range(num_lucs):
        luc = parcel_list[i]
        total_area += luc["area"]
        for j in range(luc["parcels"]):
            p = Parcel(index, 1.0, luc["name"])
            # p.ix = index
            parcels.add(p)
            index += 1
    # FIXME: probably shouldn't be storing all this stuff on the class object itself
    Allocation.total_area = float(total_area)
    Allocation.n_lucs = num_lucs
    # Allocation.initial_allocation = Allocation(parcels)
    return parcels

def calculate_init_hitogram(n_representatives,allocations):
    histo = np.zeros( n_representatives+1)
    for a in allocations:
        histo[a.n_satisfied_reps]+=1
    return histo
   
def update_histogram(histo,allocations,value):
    histo_1 = histo.copy()
    for a in allocations:
        if a.n_satisfied_reps+value>=0 and a.n_satisfied_reps+value<len(histo):
            histo_1[a.n_satisfied_reps+value] = histo_1[a.n_satisfied_reps+value]+1
            histo_1[a.n_satisfied_reps] = histo_1[a.n_satisfied_reps]-1
    return histo_1

def update_satisfied (allocations,value):
    for a in allocations:
        a.n_satisfied_reps+=value

def calculate_histo_distance(histo,histo_0):
    x = histo/Allocation.n_alloc-histo_0
    return np.sum(x*x)
