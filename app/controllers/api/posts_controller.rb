# frozen_string_literal: true
require 'json'

module Api
  # Posts controller
  class PostsController < ApplicationController
    # part 1: function to sort posts by specific criteria
    def index
      # variables for search queries
      authorIds = params[:authorIds] ? params[:authorIds].split(',') : []

      sortBy = params[:sortBy] ? params[:sortBy] : 'id'
      acceptableSortBy = ["id", "reads", "likes", "popularity"]

      direction = params[:direction]
      acceptableDirections = ["asc", "desc"]

      response = []

      # need to add more, possible move to exceptions controller
      # error parsing & show error message 
      if authorIds.length < 1
        render json: { "error": "<Author ID parameter is required>" }, status: 400 
        return
      end

      if (!acceptableSortBy.include?(sortBy) )
        render json: { "error": "<sortBy parameter is not valid>" }, status: 400
        return
      elsif (direction) && (!acceptableDirections.include?(direction) )
        render json: { "error": "<sortBy parameter is not valid>" }, status: 400
        return
      end

      # append results to an array
      for id in authorIds do
        result = Post.get_posts_by_user_id(id)
        response.push(result)
      end

      # turn nested hash array into a flat hash array 
      response = response.flatten(1).uniq

      # sort the new flat hash array by the sortBy param, use the direction param to sort by asc or desc order
      if (direction == "desc")
        response = response.sort_by { |item| item[sortBy] }.reverse
      else
        response = response.sort_by { |item| item[sortBy] }
      end  

      # render the entire result as a json response and return the status code 200 for success
      render json: { "posts": response }, status: 200
    end

    # part 2: function to update post information for patch requests
    def update
      # setting variables for parameters
      postsByCurrUser = Post.get_posts_by_user_id(@current_user).to_a.map(&:serializable_hash)
      postIds = []

      postId = params[:id].to_i
      postFound = false

      authorIds = params[:authorIds] ? params[:authorIds].split(',') : []
      authorizedUser = false

      tags = params[:tags] ? params[:tags].split(',') : []
      text = params[:text]

      postToEdit = []

      # create an array of all post ids from the author
      for post in postsByCurrUser
        postIds.push(post["id"])
      end

      # need to add more
      # error parsing & show error message
      if (!postId.present?) 
        render json: { "error": "<Post ID parameter is required>" }, status: 400 
        return
      end

      # ensure that the post exists
      for post in postsByCurrUser
        if post["id"] == postId
          postFound = true
          # authorizedUser = true
          postToEdit.push(post)
        else
          next
        end
        # ensure that the current user is an author of the chosen post
        if postIds.include? post["id"]
          authorizedUser = true
        else
          render json: { "error": "<You are not authorized to edit this post>" }, status: 400 
          return  
        end
      end  

      if !postFound
        render json: { "error": "<Post was not found or does not exist>" }, status: 400 
        return
      end

      # if the user is authorized and the post was found, update the information
      if (authorizedUser && postFound)
        if authorIds.length > 0
          postToEdit[0]["authorIds"] = authorIds
          postToEdit[0]["authorIds"] = postToEdit[0]["authorIds"][0]
        end
        if tags.length > 0
          postToEdit[0]["tags"] = tags
          postToEdit[0]["tags"] = postToEdit[0]["tags"][0]
        end
        if text.length > 0
          postToEdit[0]["text"] = text
        end
      else
          render json: { "error": "<You do not have permission to edit this post>" }, status: 400
          return
      end  

      render json: { "post": postToEdit[0] }, status: 200
    end      

    def create
      post = current_user.posts.create!(post_params)
      render json: { post: post }, status: :created
    end

    private

    def post_params
      params.permit(:text, :likes, :reads, :popularity, tags: [])
    end

  end
end