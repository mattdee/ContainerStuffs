docker run -d -p 27017:27017 --name mongoDB mongo:latest

docker exec -it mongoDB mongo
