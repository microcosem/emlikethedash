# Blog Guidelines

This directory contains the blog posts for the site. Here's how to create new posts:

## File Naming Convention

Use the format: `YYYY-MM-DD-title-with-hyphens.md`

Examples:
- `2024-01-15-welcome-to-my-blog.md`
- `2024-01-20-mkdocs-blog-setup.md`

## Post Structure

Each blog post should start with front matter:

```yaml
---
date: YYYY-MM-DD
categories:
  - Category1
  - Category2
tags:
  - tag1
  - tag2
---
```

## Available Categories

- **Technology**: Programming, tools, technical concepts
- **Projects**: Updates and insights about ongoing work
- **Tutorials**: Step-by-step guides and how-tos
- **Thoughts**: Personal reflections and industry observations

## Content Guidelines

- Write in clear, engaging prose
- Use headers to organize content
- Include code examples when relevant
- Add images or diagrams when helpful
- Keep posts focused on a single topic
- Aim for 500-2000 words per post

## Images and Assets

Store images in the `docs/blog/posts/assets/` directory and reference them using relative paths.

## Publishing

1. Create your markdown file in the `posts/` directory
2. Add appropriate front matter
3. Write your content
4. Test locally with `mkdocs serve`
5. Commit and push to publish 