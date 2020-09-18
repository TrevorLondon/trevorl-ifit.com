-- .xlsx file read
segment_feedback = pd.read_excel('x32_and_s22i_survey_data.xlsx',sheet_name='Segmented Users List')

# Wordclouds on feedback comments 
from PIL import Image
from wordcloud import Wordcloud, STOPWORDS, ImageColorGenerator
import matplotlib.pyplot as plt

#Method 1
text = segment_feedback.Feedback
wordcloud = WordCloud(max_font_size=50,max_words=100).generate(text)
plt.imshow(wordcloud, interpolation='bilinear')
plt.axis("off")
plt.show()

#Method 2
comment_words = ''
for val in less_than_five.Feedback:
    val = str(val)
    tokens = val.split()
    for i in range(len(tokens)):
        tokens[i] = tokens[i].lower()
    comment_words += " ".join(tokens)+" "
wordcloud = WordCloud(width = 800, height = 800,
                     background_color = 'white',
                     stopwords=["The","Of","To","Keep","And","As","Bike","iFit","Still","Will"],
                     min_font_size = 10,
                     max_words=100,
                     max_font_size=150).generate(comment_words)
plt.figure(figsize = (8, 8), facecolor = None)
plt.imshow(wordcloud)
plt.axis("off")
plt.tight_layout(pad = 0)

#Getting subset DF from those that gave a 5 or less rating
less_than_five = segment_feedback[(segment_feedback['Score'] < 5)]

#Getting average ratings on ENTIRE dataset, per equipment type
all_survey_users = pd.read_excel('ALL_SURVEY_USERS.xlsx',sheet_name='Master')
equip_ratings_mean = all_survey_users.groupby('type')['Rating'].mean()
print(equip_ratings_mean)
