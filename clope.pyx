# coding: utf-8

cdef class Transaction(object):

    cdef public list items
    cdef public int cluster_pos
    cdef public int cluster_id

    def __init__(self, list items):
        self.cluster_pos = 0
        self.cluster_id = 0
        self.items = items


cdef class Cluster(object):

    cdef public int id
    cdef public int n
    cdef public int s
    cdef public int w
    cdef public dict occ
    cdef public list transactions

    def __init__(self, int cluster_id, Transaction transaction):
        self.id = cluster_id
        self.n = 1
        self.s = self.w = len(transaction.items)
        self.occ = {item: 1 for item in transaction.items}
        self.transactions = [transaction]
        transaction.cluster_id = cluster_id

    def __str__(self):
        return "<Cluster %s: %s>" % (self.id, len(self.transactions))

cdef void add_transaction(Cluster cluster, Transaction transaction):
    for item in transaction.items:
        cluster.occ[item] = cluster.occ.get(item, 0) + 1
    transaction.cluster_id = cluster.id
    transaction.cluster_pos = len(cluster.transactions)
    cluster.transactions.append(transaction)
    cluster.s += len(transaction.items)
    cluster.w = len(cluster.occ)
    cluster.n += 1

cdef void remove_transaction(Cluster cluster, Transaction transaction):
    for item in transaction.items:
        if cluster.occ.get(item) == 1:
            del cluster.occ[item]
        else:
            cluster.occ[item] -= 1
    cluster.transactions[transaction.cluster_pos] = None
    cluster.s -= len(transaction.items)
    cluster.w = len(cluster.occ)
    cluster.n -= 1


cdef list _clear_empty_transactions(list clusters):
    for cluster in clusters:
        cluster.transactions = filter(None, cluster.transactions)
        cluster.n = len(cluster.transactions)
    return clusters

cdef list _clear_empty_clusters(list clusters):
    return filter(lambda c: c.n > 0, clusters)

cpdef list clusterize(list transactions, double repulsion=4.0):
    return _clusterize(transactions, repulsion)

cdef list _clusterize(list transactions, double repulsion=4.0):
    cdef list clusters = []

    for transaction in transactions:
        clusters = add_instance_to_best_cluster(
            clusters, transaction, repulsion
        )

    while True:
        moved = False

        for transaction in transactions:
            original_cluster_id = transaction.cluster_id
            remove_transaction(clusters[original_cluster_id], transaction)
            clusters = add_instance_to_best_cluster(
                clusters, transaction, repulsion
            )
            if transaction.cluster_id != original_cluster_id:
                moved = True

        if not moved:
            break

    return _clear_empty_clusters(_clear_empty_transactions(clusters))

cdef double get_delta(int s, int w, int n, dict occ, list items, double r):
    cdef int ilen = len(items)
    cdef int w_new = w
    cdef int s_new = s + ilen
    if n == 0:
        return ilen / (ilen ** r)
    else:
        w_new = w
        s_new = s + ilen
        for item in items:
            if not occ.get(item):
                w_new += 1
        profit = s * n / (w ** r)
        profit_new = s_new * (n + 1) / (w_new ** r)
        delta_profit = profit_new - profit
    return delta_profit


cdef list add_instance_to_best_cluster(list clusters, Transaction transaction, double repulsion):
    best_cluster = None
    cdef list items = transaction.items
    cdef int temp_s = len(items)
    cdef int temp_w = temp_s
    cdef double best_delta = 0
    cdef double max_delta = temp_s / (temp_w ** repulsion)

    for cluster in clusters:
        delta = get_delta(cluster.s, cluster.w, cluster.n, cluster.occ, items, repulsion)
        if delta > best_delta:
            if delta > max_delta:
                add_transaction(cluster, transaction)
                return clusters
            else:
                best_delta = delta
                best_cluster = cluster

    if best_delta >= max_delta:
        add_transaction(best_cluster, transaction)
        return clusters

    clusters.append(Cluster(len(clusters), transaction))
    return clusters
