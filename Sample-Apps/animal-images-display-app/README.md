# Animal Album Application

This is a simple application that displays images of animals. The images are displayed in a grid view. The UI is built using React and the backend is built using Python FastAPI.

## Tech Stack

- React
- FastAPI
- Docker
- MongoDB
- MinIO

## Application Architecture

The application consists of three microservices:

1. **Frontend Service**: Built with React, responsible for the user interface.
2. **Data Service**: Built with FastAPI, responsible for retrieving data from the database.
3. **Image Service**: Built with FastAPI, responsible for retrieving images from the object storage.

## Flow Diagram

![Flow Diagram](../../Docs/media/AnimalAppArch.svg)

## Setup

The entire application is set up on a Kubernetes cluster in the `animal` namespace. Istio is used for traffic management and routing.