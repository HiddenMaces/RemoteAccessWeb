**docker run -d -p 443:433 -v $(pwd)/links.txt:/app/links.txt my-portal**

volumes:
      # This syncs the text file from your computer to the container
      - ./links.txt:/app/links.txt

      