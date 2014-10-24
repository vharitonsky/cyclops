# coding: utf-8


class Transaction(object):
    __slots__ = ['items', 'cluster_id', 'cluster_pos']

    def __init__(self, items):
        self.cluster_pos = 0
        self.cluster_id = 0
        self.items = items


class Cluster(object):

    __slots__ = [
        'id', 'occ', 'transactions', 'add_item', 'delete_item', 'n', 'w', 's',
        'delta_add', 'add_instance', 'delete_instance'
    ]

    def __init__(self, cluster_id, transaction):
        self.id = cluster_id
        self.n = 1
        self.s = self.w = len(transaction.items)
        self.occ = {item: 1 for item in transaction.items}
        self.transactions = [transaction]
        transaction.cluster_id = cluster_id

    def __str__(self):
        return "<Cluster %s: %s>" % (self.id, len(self.transactions))

    def add_item(self, item):
        if item in self.occ:
            self.occ[item] += 1
        else:
            self.occ[item] = 1

    def delete_item(self, item):
        if self.occ[item] == 1:
            del self.occ[item]
        else:
            self.occ[item] -= 1

    def get_delta(self, items, r):
        s_new = self.s + len(items)
        w_new = self.w

        for item in items:
            if item not in self.occ:
                w_new += 1

        if self.n == 0:
            delta_profit = s_new / (w_new ** r)
        else:
            profit = self.s * self.n / (self.w ** r)
            profit_new = s_new * (self.n + 1) /(w_new **r)
            delta_profit = profit_new - profit

        return delta_profit

    def add_transaction(self, transaction):
        for item in transaction.items:
            self.add_item(item)
        transaction.cluster_id = self.id
        transaction.cluster_pos = len(self.transactions)
        self.transactions.append(transaction)
        self.s += len(transaction.items)
        self.w = len(self.occ)
        self.n += 1

    def remove_transaction(self, transaction):
        for item in transaction.items:
            self.delete_item(item)

        self.transactions[transaction.cluster_pos] = None
        transaction.cluster_id = None
        self.s -= len(transaction.items)
        self.w = len(self.occ)
        self.n -= 1


def _clear_empty_transactions(clusters):
    for cluster in clusters:
        cluster.transactions = filter(None, cluster.transactions)
    return clusters


def _clear_empty_clusters(clusters):
    return filter(lambda c: len(c.transactions) > 0, clusters)


def clusterize(transactions, repulsion=4.0):
    clusters = []

    for i, transaction in enumerate(transactions):
        clusters = add_instance_to_best_cluster(
            clusters, transaction, repulsion
        )

    while True:
        moved = False

        for i, transaction in enumerate(transactions):
            original_cluster_id = transaction.cluster_id
            clusters[original_cluster_id].remove_transaction(transaction)
            clusters = add_instance_to_best_cluster(
                clusters, transaction, repulsion
            )
            if transaction.cluster_id != original_cluster_id:
                moved = True


        if not moved:
            break

    return _clear_empty_clusters(_clear_empty_transactions(clusters))


def add_instance_to_best_cluster(clusters, transaction, repulsion):
    best_cluster = None
    items = transaction.items
    temp_s = len(items)
    temp_w = temp_s

    max_delta = temp_s / (temp_w ** repulsion)
    best_delta = 0
    for i, cluster in enumerate(clusters):
        delta = cluster.get_delta(items, repulsion)
        if delta > best_delta:
            if delta > max_delta:
                cluster.add_transaction(transaction)
                return clusters
            else:
                best_delta = delta
                best_cluster = cluster

    if best_delta >= max_delta:
        best_cluster.add_transaction(transaction)
        return clusters

    clusters.append(Cluster(len(clusters), transaction))
    return clusters
