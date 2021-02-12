# Memcache
## Run the server
First of all, we need to get the server/bin running. For it, in the folder server we execute

`ruby server.rb {port we wish to use}`

As we can see in the next image.
![alt text](images/server.png)  
To shutdown the server correctly we can do it with ctrl + c or ctrl + z.

## Run the client
The client only works, if it is run in the same machine that the server. That is because it is
configured to use the interface 127.0.0.1 that is local to the machine. We can simply solve
this changing the next line.
![alt text](images/tcpsocket.png)
