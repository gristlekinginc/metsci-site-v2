#!/usr/bin/env python3
"""
MeteoScientific llms.txt Generator

Generates llms.txt and llms-full.txt files for the MeteoScientific documentation site.
Processes docs/ (tutorials) and blog/ (filtering by author) using OpenAI to enhance content.
"""

import os
import json
import yaml
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from openai import OpenAI
from dotenv import load_dotenv

# Change to project root directory (parent of scripts/)
script_dir = Path(__file__).parent
project_root = script_dir.parent
os.chdir(project_root)

# Load environment variables
load_dotenv()

@dataclass
class ContentItem:
    title: str
    path: str
    content: str
    frontmatter: Dict
    content_type: str  # 'tutorial', 'blog', 'category'
    # Enhanced fields based on the improved prompt
    intent: Optional[str] = None
    summary: Optional[str] = None
    keywords: Optional[List[str]] = None
    entities: Optional[List[str]] = None
    prerequisites: Optional[List[str]] = None
    related_topics: Optional[List[str]] = None
    difficulty: Optional[str] = None

class MeteoScientificLLMSGenerator:
    def __init__(self, debug=False, limit=None):
        self.client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        self.base_url = "https://meteoscientific.com"
        self.content_items: List[ContentItem] = []
        self.debug = debug
        self.limit = limit
        
        # Ensure we're in the right directory
        print(f"Working directory: {os.getcwd()}")
        if not Path('docs').exists() or not Path('blog').exists():
            raise FileNotFoundError("Could not find docs/ or blog/ directories. Make sure you're running from the project root.")
        
        # Check API key
        api_key = os.getenv('OPENAI_API_KEY')
        if not api_key:
            raise ValueError("OPENAI_API_KEY not found in environment variables")
        if self.debug:
            print(f"🔑 API Key loaded: {api_key[:20]}...")
        
    def parse_frontmatter(self, content: str) -> Tuple[Dict, str]:
        """Extract frontmatter and content from markdown file."""
        if content.startswith('---'):
            try:
                end_marker = content.find('---', 3)
                if end_marker != -1:
                    frontmatter_text = content[3:end_marker].strip()
                    content_text = content[end_marker + 3:].strip()
                    frontmatter = yaml.safe_load(frontmatter_text) or {}
                    return frontmatter, content_text
            except yaml.YAMLError:
                pass
        return {}, content

    def should_include_blog(self, frontmatter: Dict) -> bool:
        """Determine if blog post should be included based on author."""
        authors = frontmatter.get('authors', [])
        if not authors:
            return False
        
        # Include if nik is an author (solo or co-author)
        return 'nik' in authors

    def load_docs_content(self):
        """Load all documentation content from docs/ directory."""
        docs_path = Path('docs')
        
        # Process category files first
        for category_file in docs_path.glob('*/_category_.json'):
            with open(category_file, 'r') as f:
                category_data = json.load(f)
                
            category_path = category_file.parent
            self.content_items.append(ContentItem(
                title=f"Category: {category_data.get('label', category_path.name)}",
                path=str(category_path.relative_to('docs')),
                content=category_data.get('description', ''),
                frontmatter=category_data,
                content_type='category'
            ))
        
        # Process markdown files
        for md_file in docs_path.glob('**/*.md'):
            with open(md_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            frontmatter, content_text = self.parse_frontmatter(content)
            
            self.content_items.append(ContentItem(
                title=frontmatter.get('title', md_file.stem.replace('-', ' ').title()),
                path=str(md_file.relative_to('docs')),
                content=content_text,
                frontmatter=frontmatter,
                content_type='tutorial'
            ))

    def load_blog_content(self):
        """Load blog content, filtering by author."""
        blog_path = Path('blog')
        
        for md_file in blog_path.glob('*.md'):
            with open(md_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            frontmatter, content_text = self.parse_frontmatter(content)
            
            if self.should_include_blog(frontmatter):
                self.content_items.append(ContentItem(
                    title=frontmatter.get('title', md_file.stem),
                    path=f"blog/{md_file.name}",
                    content=content_text,
                    frontmatter=frontmatter,
                    content_type='blog'
                ))

    def enhance_content_with_ai(self, item: ContentItem) -> ContentItem:
        """Enhance content item using the improved SEO-focused prompt."""
        
        # Skip categories for now - they have minimal content
        if item.content_type == 'category':
            if self.debug:
                print(f"🔄 Skipping category: {item.title}")
            item.intent = f"Navigate to {item.title.lower()}"
            item.summary = f"Browse content in the {item.title.lower()} section"
            item.keywords = ["LoRaWAN", "documentation"]
            item.entities = []
            item.prerequisites = []
            item.related_topics = []
            item.difficulty = "Beginner"
            return item
        
        # Determine content-specific context
        if item.content_type == 'tutorial':
            context = "LoRaWAN educational tutorial for beginners to intermediate learners"
        elif item.content_type == 'blog':
            context = "LoRaWAN industry insights and practical applications blog post"
        else:
            context = "LoRaWAN documentation category"

        # Use the sophisticated prompt from llm-text-prompt.txt
        enhancement_prompt = f"""You are an expert content summarizer for MeteoScientific, a LoRaWAN education platform teaching IoT concepts from beginner to advanced levels. Your task is to generate an optimized summary for an `llms.txt` file to enhance LLM SEO for tutorials and blog posts, prioritizing discoverability for LoRaWAN and IoT-related topics.

CONTEXT: This is a {context}.
CONTENT TITLE: {item.title}
CONTENT TYPE: {item.content_type}
CONTENT: {item.content[:3000]}...

Analyze the content and provide a structured JSON output with:

1. **title**: The exact title of the content.
2. **intent**: A single sentence describing the primary user intent or problem solved (e.g., "Learn how to configure a LoRaWAN gateway").
3. **summary**: A 50-75 word description of the content, covering the core topic, key steps or concepts, and target audience (e.g., beginners, IoT engineers). Emphasize LoRaWAN and IoT relevance to align with search intents.
4. **keywords**: 5-10 precise, contextually relevant keywords or phrases derived directly from the content, focusing on LoRaWAN and IoT terms (e.g., "LoRaWAN gateway", "IoT sensor", "ChirpStack").
5. **entities**: 3-5 specific tools, protocols, or technologies mentioned (e.g., the Helium Network, ChirpStack, LoRa, MQTT).
6. **prerequisites**: 2-4 LoRaWAN concepts or prior tutorials readers should know, specific to the content's difficulty.
7. **related_topics**: 3-5 MeteoScientific topics or tutorials that naturally follow or complement the content.
8. **difficulty**: A single word or short phrase indicating the skill level (e.g., Beginner, Intermediate, Advanced).

Ensure the output is factual, uses precise LoRaWAN and IoT terminology, and maximizes semantic clarity for LLMs. Derive keywords naturally from the content, prioritizing terms that align with LoRaWAN and IoT search intents. 

IMPORTANT: Respond with raw JSON only - do not use markdown code blocks or any other formatting. Return only the JSON object:

{{
  "title": "{item.title}",
  "intent": "Single sentence describing user intent",
  "summary": "50-75 word summary emphasizing LoRaWAN/IoT",
  "keywords": ["keyword1", "keyword2", ...],
  "entities": ["entity1", "entity2", ...],
  "prerequisites": ["prereq1", "prereq2", ...],
  "related_topics": ["topic1", "topic2", ...],
  "difficulty": "Beginner|Intermediate|Advanced"
}}

Focus on making this content discoverable and useful for AI assistants helping people learn LoRaWAN technology."""

        try:
            if self.debug:
                print(f"🔍 Sending prompt for: {item.title}")
                print(f"📝 Content length: {len(item.content)} chars")
            
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": enhancement_prompt}],
                temperature=0.3,
                max_tokens=800
            )
            
            response_text = response.choices[0].message.content
            
            if self.debug:
                print(f"🤖 Raw response for {item.title}:")
                print(f"   Length: {len(response_text)} chars")
                print(f"   First 200 chars: {response_text[:200]}...")
            
            if not response_text or not response_text.strip():
                raise ValueError("Empty response from OpenAI")
            
            result = json.loads(response_text.strip())
            
            # Map the improved fields
            item.intent = result.get('intent', '')
            item.summary = result.get('summary', '')
            item.keywords = result.get('keywords', [])
            item.entities = result.get('entities', [])
            item.prerequisites = result.get('prerequisites', [])
            item.related_topics = result.get('related_topics', [])
            item.difficulty = result.get('difficulty', 'Beginner')
            
            print(f"✓ Enhanced: {item.title} ({item.difficulty})")
            
        except json.JSONDecodeError as e:
            print(f"✗ JSON Error for {item.title}: {e}")
            if self.debug:
                print(f"   Response text: {response_text}")
            # Fallback to basic summary
            item.intent = f"Learn about {item.title.lower()}"
            item.summary = f"Learn about {item.title.lower()} in the context of LoRaWAN and IoT applications."
            item.keywords = ["LoRaWAN", "IoT"]
            item.entities = []
            item.prerequisites = []
            item.related_topics = []
            item.difficulty = "Beginner"
        except Exception as e:
            print(f"✗ Failed to enhance {item.title}: {e}")
            # Fallback to basic summary
            item.intent = f"Learn about {item.title.lower()}"
            item.summary = f"Learn about {item.title.lower()} in the context of LoRaWAN and IoT applications."
            item.keywords = ["LoRaWAN", "IoT"]
            item.entities = []
            item.prerequisites = []
            item.related_topics = []
            item.difficulty = "Beginner"
        
        return item

    def generate_llms_txt(self) -> str:
        """Generate the structured llms.txt content with enhanced SEO data."""
        
        # Sort content by type and importance
        tutorials = [item for item in self.content_items if item.content_type == 'tutorial']
        blogs = [item for item in self.content_items if item.content_type == 'blog']
        
        # Sort tutorials by sidebar_position if available
        tutorials.sort(key=lambda x: x.frontmatter.get('sidebar_position', 999))
        
        # Sort blogs by date (newest first)
        blogs.sort(key=lambda x: x.frontmatter.get('date', '2020-01-01'), reverse=True)
        
        llms_content = []
        
        # Header
        llms_content.append("# MeteoScientific LoRaWAN Documentation")
        llms_content.append("")
        llms_content.append("> Comprehensive guides for learning LoRaWAN technology, from basic concepts to real-world IoT deployments. Covers ChirpStack configuration, device management, and practical applications for businesses and developers.")
        llms_content.append("")
        
        # Site structure explanation
        llms_content.append("This documentation follows a structured learning path: foundational LoRaWAN concepts → hands-on device configuration → advanced integrations and business applications. Content is human-written by LoRaWAN practitioners with real-world deployment experience.")
        llms_content.append("")
        
        # Tutorial Basics
        basic_tutorials = [t for t in tutorials if 'tutorial-basics' in t.path]
        if basic_tutorials:
            llms_content.append("## Tutorial - Basics")
            llms_content.append("Essential LoRaWAN concepts and step-by-step device setup guides.")
            llms_content.append("")
            for tutorial in basic_tutorials:
                url = f"{self.base_url}/docs/{tutorial.path.replace('.md', '')}"
                summary = tutorial.summary or f"Learn about {tutorial.title.lower()}"
                difficulty = f" ({tutorial.difficulty})" if tutorial.difficulty else ""
                llms_content.append(f"- [{tutorial.title}]({url}): {summary}{difficulty}")
            llms_content.append("")
        
        # Tutorial Extras
        extra_tutorials = [t for t in tutorials if 'tutorial-extras' in t.path]
        if extra_tutorials:
            llms_content.append("## Tutorial - Advanced")
            llms_content.append("Advanced integrations, troubleshooting, and real-world deployment strategies.")
            llms_content.append("")
            for tutorial in extra_tutorials:
                url = f"{self.base_url}/docs/{tutorial.path.replace('.md', '')}"
                summary = tutorial.summary or f"Learn about {tutorial.title.lower()}"
                difficulty = f" ({tutorial.difficulty})" if tutorial.difficulty else ""
                llms_content.append(f"- [{tutorial.title}]({url}): {summary}{difficulty}")
            llms_content.append("")
        
        # Other docs sections
        other_tutorials = [t for t in tutorials if 'tutorial-basics' not in t.path and 'tutorial-extras' not in t.path and t.content_type == 'tutorial']
        if other_tutorials:
            llms_content.append("## Reference Documentation")
            llms_content.append("Specialized guides and reference materials.")
            llms_content.append("")
            for tutorial in other_tutorials:
                url = f"{self.base_url}/docs/{tutorial.path.replace('.md', '')}"
                summary = tutorial.summary or f"Learn about {tutorial.title.lower()}"
                difficulty = f" ({tutorial.difficulty})" if tutorial.difficulty else ""
                llms_content.append(f"- [{tutorial.title}]({url}): {summary}{difficulty}")
            llms_content.append("")
        
        # Blog posts
        if blogs:
            llms_content.append("## Industry Insights & Applications")
            llms_content.append("Real-world case studies and practical applications of LoRaWAN technology.")
            llms_content.append("")
            for blog in blogs[:10]:  # Limit to 10 most recent
                url = f"{self.base_url}/{blog.path.replace('.md', '')}"
                summary = blog.summary or blog.frontmatter.get('description', f"Read about {blog.title.lower()}")
                llms_content.append(f"- [{blog.title}]({url}): {summary}")
            llms_content.append("")
        
        # Optional section for additional resources
        llms_content.append("## Optional")
        llms_content.append("Additional resources and community information.")
        llms_content.append("")
        llms_content.append(f"- [MeteoScientific Console]({self.base_url}/console): Free LoRaWAN network server for testing and development")
        llms_content.append(f"- [Contact Support]({self.base_url}/contact): Technical support and consultation services")
        llms_content.append("- [Discord Community](https://discord.gg/PAjUSky9Hp): Join the #meteoscientific channel for help")
        
        return "\n".join(llms_content)

    def generate_llms_full_txt(self) -> str:
        """Generate the complete concatenated content with enhanced metadata."""
        full_content = []
        
        full_content.append("# MeteoScientific Complete Documentation")
        full_content.append(f"Generated on {datetime.now().strftime('%Y-%m-%d')}")
        full_content.append("")
        full_content.append("This file contains the complete text of MeteoScientific's LoRaWAN documentation and selected blog posts, optimized for AI consumption with enhanced metadata.")
        full_content.append("")
        full_content.append("=" * 80)
        full_content.append("")
        
        # Process all content items with enhanced metadata
        for item in self.content_items:
            full_content.append(f"## {item.title}")
            full_content.append(f"Path: {item.path}")
            full_content.append(f"Type: {item.content_type}")
            
            if item.intent:
                full_content.append(f"Intent: {item.intent}")
            
            if item.summary:
                full_content.append(f"Summary: {item.summary}")
            
            if item.difficulty:
                full_content.append(f"Difficulty: {item.difficulty}")
            
            if item.keywords:
                full_content.append(f"Keywords: {', '.join(item.keywords)}")
            
            if item.entities:
                full_content.append(f"Technologies: {', '.join(item.entities)}")
            
            if item.prerequisites:
                full_content.append(f"Prerequisites: {', '.join(item.prerequisites)}")
            
            if item.related_topics:
                full_content.append(f"Related Topics: {', '.join(item.related_topics)}")
            
            full_content.append("")
            full_content.append(item.content)
            full_content.append("")
            full_content.append("-" * 80)
            full_content.append("")
        
        return "\n".join(full_content)

    def run(self):
        """Main execution function."""
        print("🚀 MeteoScientific llms.txt Generator")
        if self.limit:
            print(f"🔬 DEBUG MODE: Processing only first {self.limit} items")
        print("=" * 50)
        
        # Load content
        print("📁 Loading documentation content...")
        self.load_docs_content()
        
        print("📝 Loading blog content (filtering by author)...")
        self.load_blog_content()
        
        # Apply limit if set
        if self.limit:
            self.content_items = self.content_items[:self.limit]
        
        print(f"📊 Found {len(self.content_items)} content items")
        
        # Enhance with AI
        print("\n🤖 Enhancing content with SEO-optimized prompts...")
        for i, item in enumerate(self.content_items, 1):
            print(f"[{i}/{len(self.content_items)}] Processing: {item.title}")
            self.content_items[self.content_items.index(item)] = self.enhance_content_with_ai(item)
        
        # Generate outputs
        print("\n📋 Generating llms.txt...")
        llms_txt_content = self.generate_llms_txt()
        
        print("📄 Generating llms-full.txt...")
        llms_full_content = self.generate_llms_full_txt()
        
        # Write files
        print("\n💾 Writing output files...")
        
        with open('static/llms.txt', 'w', encoding='utf-8') as f:
            f.write(llms_txt_content)
        print("✓ Created static/llms.txt")
        
        with open('static/llms-full.txt', 'w', encoding='utf-8') as f:
            f.write(llms_full_content)
        print("✓ Created static/llms-full.txt")
        
        print(f"\n🎉 Complete! Files will be available at:")
        print(f"   {self.base_url}/llms.txt")
        print(f"   {self.base_url}/llms-full.txt")

if __name__ == "__main__":
    import sys
    
    # Check for debug and limit flags
    debug = "--debug" in sys.argv
    limit = None
    
    for arg in sys.argv:
        if arg.startswith("--limit="):
            limit = int(arg.split("=")[1])
    
    generator = MeteoScientificLLMSGenerator(debug=debug, limit=limit)
    generator.run() 