// Algorithm from https://www.geeksforgeeks.org/c/shortest-path-algorithm-in-c/

#include "hpm_boom.h"

// C Program to Implement Shortest Path Algorithm
#include <limits.h>
#include <stdio.h>

// adding this for random matrix
#include <stdlib.h> 

// Number of vertices in the graph
#define V 5 // Changing to increase cycles

// Function to find the vertex with the minimum distance
// value from the set of vertices not yet included in the
// shortest path tree
int findminDistance(int dist[], int included[])
{
    int min = INT_MAX, min_index;

    // Traverse all vertices to find the vertex with the
    // minimum distance value
    for (int v = 0; v < V; v++) {
        if (included[v] == 0 && dist[v] <= min) {
            min = dist[v];
            min_index = v;
        }
    }
    return min_index;
}

// Function to print the constructed distance array
void printSolution(int dist[])
{
    printf("Vertex \t Distance from Source\n");
    for (int i = 0; i < V; i++) {
        printf("%d \t\t %d\n", i, dist[i]);
    }
}

// Function that implements Dijkstra's algorithm
int DijkstrasAlgo(int graph[V][V], int src)
{
    // Array to store the minimum distance from source node
    // to the current node
    int dist[V];
    // Array to keep track of included nodes
    int included[V];

    // Initialize all distances as INFINITE and included as
    // false
    for (int i = 0; i < V; i++) {
        dist[i] = INT_MAX;
        included[i] = 0;
    }

    // Distance of source vertex from itself is always 0
    dist[src] = 0;

    // Find the shortest path for all vertices
    for (int count = 0; count < V - 1; count++) {
        // Pick the minimum distance vertex from the set of
        // vertices not yet processed
        int u = findminDistance(dist, included);

        // Mark the selected vertex as included
        included[u] = 1;

        // Update the distance of all the adjacent vertices
        // of the selected vertex
        for (int v = 0; v < V; v++) {
            // update dist[v] if it is already note included
            // and the current distance is less then it's
            // original distance
            if (!included[v] && graph[u][v]
                && dist[u] != INT_MAX
                && dist[u] + graph[u][v] < dist[v]) {
                dist[v] = dist[u] + graph[u][v];
            }
        }
    }

    // Adding this b/c compiler optimized out code
    int total_dist = 0;
    for (int i = 0; i < V; i++) {
        total_dist += dist[i];
    }

    return total_dist;

    // Print the constructed distance array
    // printSolution(dist); // caused extra cycles waiting to print
}

int main()
{

    // int graph[V][V] = {
    //     { 0, 1, 4, 6, 1 }, // Node A (0) connections
    //     { 1, 0, 0, 2, 0 }, // Node B (1) connections
    //     { 4, 0, 0, 0, 1 }, // Node C (2) connections
    //     { 6, 2, 0, 0, 5 }, // Node D (3) connections
    //     { 1, 0, 1, 5, 0 } // Node E (4) connections
    // };

    static int graph[V][V] = {
        {0, 12, 5, 18, 9, 3, 15, 7, 11, 4, 19, 2, 14, 6, 8, 17, 10, 1, 13, 16},
        {14, 0, 9, 2, 17, 11, 6, 19, 4, 8, 15, 3, 10, 1, 18, 7, 12, 5, 16, 13},
        {8, 15, 0, 13, 5, 19, 2, 10, 16, 1, 7, 12, 4, 18, 11, 6, 9, 17, 3, 14},
        {19, 6, 11, 0, 14, 2, 8, 17, 3, 12, 5, 18, 9, 15, 1, 10, 4, 13, 7, 16},
        {3, 17, 7, 10, 0, 13, 19, 4, 15, 6, 1, 11, 18, 5, 12, 2, 16, 8, 14, 9},
        {11, 4, 18, 15, 2, 0, 13, 9, 7, 17, 10, 14, 3, 12, 6, 19, 1, 16, 8, 5},
        {6, 13, 2, 8, 16, 5, 0, 12, 18, 3, 14, 7, 15, 10, 19, 4, 11, 2, 9, 17},
        {15, 9, 14, 3, 11, 18, 7, 0, 2, 16, 6, 19, 1, 13, 5, 12, 17, 10, 4, 8},
        {2, 18, 10, 17, 6, 12, 4, 14, 0, 9, 13, 5, 16, 8, 3, 15, 7, 19, 11, 1},
        {17, 5, 12, 1, 8, 15, 11, 2, 19, 0, 4, 10, 7, 16, 14, 3, 18, 6, 13, 9},
        {10, 2, 16, 7, 19, 4, 15, 6, 12, 14, 0, 8, 17, 3, 9, 11, 5, 18, 1, 13},
        {5, 11, 8, 19, 1, 16, 3, 13, 6, 18, 12, 0, 10, 7, 17, 9, 14, 4, 15, 2},
        {13, 7, 19, 5, 12, 9, 17, 1, 10, 15, 2, 16, 0, 4, 11, 8, 3, 14, 6, 18},
        {4, 16, 1, 12, 7, 10, 14, 18, 5, 11, 9, 2, 19, 0, 13, 16, 8, 3, 17, 6},
        {9, 3, 15, 6, 18, 7, 1, 11, 13, 5, 17, 15, 12, 19, 0, 14, 2, 10, 16, 4},
        {18, 10, 4, 14, 13, 1, 16, 8, 9, 2, 11, 6, 5, 17, 10, 0, 15, 7, 12, 3},
        {7, 19, 6, 11, 4, 17, 10, 5, 14, 13, 18, 1, 8, 2, 16, 5, 0, 12, 9, 15},
        {12, 8, 17, 16, 10, 3, 5, 15, 1, 7, 19, 13, 6, 14, 2, 18, 11, 0, 5, 19},
        {16, 1, 13, 9, 15, 8, 12, 3, 17, 19, 5, 4, 11, 18, 7, 1, 6, 15, 0, 10},
        {1, 14, 3, 4, 17, 6, 9, 16, 8, 10, 3, 17, 2, 11, 4, 13, 19, 9, 18, 0}
    };

    // Perform Dijkstra's algorithm starting from vertex 0
    // (Node A)

    hpm_init(); // Adding hpm init

    int dist = DijkstrasAlgo(graph, 0);

    hpm_print(); // Adding hpm print

    printf("dist: %d\n", dist);

    return 0;
}